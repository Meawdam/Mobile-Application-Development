const borrowsRepository = require("./borrow_repository");
const assetsRepository = require("../asset/asset_repository");
const {
  toDateOnlyString,
  todayDateString,
  rentalDaysInclusive,
} = require("../../utils/date_utils");

class BorrowService {
  async getAllBorrows() {
    return await borrowsRepository.findAll();
  }

  async getMyBorrows(borrowerId) {
    return await borrowsRepository.findByBorrowerId(borrowerId);
  }

  async getMyLendingBorrows(ownerId) {
    return await borrowsRepository.findByOwnerId(ownerId);
  }

  async requestBorrow(borrowerId, { asset_id, pickup_date, return_date }) {
    const asset = await assetsRepository.findById(asset_id);
    if (!asset) {
      const err = new Error("Asset not found");
      err.status = 404;
      throw err;
    }

    const lendingEndDate = toDateOnlyString(asset.return_before);
    if (!lendingEndDate) {
      const err = new Error("The asset does not have a valid lending end date");
      err.status = 400;
      throw err;
    }

    const today = todayDateString();
    if (lendingEndDate < today) {
      const err = new Error("The asset lending end date has passed");
      err.status = 400;
      throw err;
    }

    const pickupDate = toDateOnlyString(pickup_date);
    const plannedReturnDate = toDateOnlyString(return_date);
    if (!pickupDate || !plannedReturnDate) {
      const err = new Error("pickup_date and return_date must be YYYY-MM-DD");
      err.status = 400;
      throw err;
    }

    if (pickupDate < today) {
      const err = new Error("pickup_date cannot be in the past");
      err.status = 400;
      throw err;
    }

    if (plannedReturnDate < pickupDate) {
      const err = new Error("return_date cannot be before pickup_date");
      err.status = 400;
      throw err;
    }

    if (pickupDate > lendingEndDate || plannedReturnDate > lendingEndDate) {
      const err = new Error(
        "Selected dates must stay within the lender's lending end date",
      );
      err.status = 400;
      throw err;
    }

    if (asset.owner_id === borrowerId) {
      const err = new Error("You cannot borrow your own asset");
      err.status = 400;
      throw err;
    }

    if (asset.status !== "ready" || asset.approval !== "approved") {
      const err = new Error("Asset is not available for borrowing");
      err.status = 400;
      throw err;
    }

    const rentalDays = rentalDaysInclusive(pickupDate, plannedReturnDate);
    const rentalAmount = Number(asset.price) * rentalDays;
    const depositAmount = Math.round(Number(asset.down_payment));
    const totalAmount = rentalAmount + depositAmount;

    const borrowId = await borrowsRepository.createBorrow({
      asset_id,
      borrower_id: borrowerId,
      pickup_date: pickupDate,
      planned_return_date: plannedReturnDate,
      rental_days: rentalDays,
      rental_amount: rentalAmount,
      deposit_amount: depositAmount,
      total_amount: totalAmount,
    });

    return {
      id: borrowId,
      asset_id,
      pickup_date: pickupDate,
      planned_return_date: plannedReturnDate,
      rental_days: rentalDays,
      price_per_day: Number(asset.price),
      rental_amount: rentalAmount,
      rental_subtotal: rentalAmount,
      deposit: depositAmount,
      deposit_amount: depositAmount,
      total_amount: totalAmount,
      lending_end_date: lendingEndDate,
      status: "requested",
      payment_status: "unpaid",
    };
  }

  async getBorrowById(borrowId, user) {
    const borrow = await borrowsRepository.findById(borrowId);
    if (!borrow) {
      const err = new Error("Borrow record not found");
      err.status = 404;
      throw err;
    }

    const isBorrower = borrow.borrower_id === user.id;
    const isOwner = borrow.owner_id === user.id;
    const isAdmin = user.role === "admin";
    if (!isBorrower && !isOwner && !isAdmin) {
      const err = new Error("Forbidden");
      err.status = 403;
      throw err;
    }

    return borrow;
  }

  async processPayment(borrowId, borrowerId) {
    const borrow = await borrowsRepository.findById(borrowId);
    if (!borrow) {
      const err = new Error("Borrow record not found");
      err.status = 404;
      throw err;
    }

    if (borrow.borrower_id !== borrowerId) {
      const err = new Error("Forbidden: You are not the borrower of this item");
      err.status = 403;
      throw err;
    }

    if (borrow.status !== "requested" || borrow.payment_status !== "unpaid") {
      const err = new Error("Borrow request is no longer awaiting payment");
      err.status = 400;
      throw err;
    }

    const updated = await borrowsRepository.markBorrowed(
      borrowId,
      borrowerId,
      borrow.asset_id,
    );
    if (!updated) {
      const err = new Error("Borrow request is no longer awaiting payment");
      err.status = 409;
      throw err;
    }

    return {
      message: "Payment completed and asset borrowed successfully",
      data: {
        borrow_id: borrowId,
        total_amount: updated.total_amount,
        wallet_balance: updated.wallet_balance,
        payment_status: "paid",
        status: "borrowed",
      },
    };
  }

  async cancelRequest(borrowId, borrowerId) {
    const borrow = await borrowsRepository.findById(borrowId);
    if (!borrow) {
      const err = new Error("Borrow record not found");
      err.status = 404;
      throw err;
    }

    if (borrow.borrower_id !== borrowerId) {
      const err = new Error("Forbidden: You are not the borrower of this item");
      err.status = 403;
      throw err;
    }

    if (borrow.status !== "requested" || borrow.payment_status !== "unpaid") {
      const err = new Error("Only unpaid borrow requests can be cancelled");
      err.status = 400;
      throw err;
    }

    const cancelled = await borrowsRepository.cancelRequest(
      borrowId,
      borrowerId,
    );
    if (!cancelled) {
      const err = new Error("Borrow request is no longer available to cancel");
      err.status = 409;
      throw err;
    }

    return { message: "Borrow request cancelled" };
  }

  async returnAsset(borrowId, borrowerId) {
    const borrow = await borrowsRepository.findById(borrowId);
    if (!borrow) {
      const err = new Error("Borrow record not found");
      err.status = 404;
      throw err;
    }

    if (borrow.borrower_id !== borrowerId) {
      const err = new Error("Forbidden: You are not the borrower of this item");
      err.status = 403;
      throw err;
    }

    if (borrow.status === "returned_confirmed") {
      const err = new Error("This item has already been returned");
      err.status = 400;
      throw err;
    }

    if (borrow.status === "returned_pending") {
      const err = new Error(
        "Return request is already waiting for owner confirmation",
      );
      err.status = 400;
      throw err;
    }

    if (borrow.status !== "borrowed") {
      const err = new Error("Only borrowed items can be returned");
      err.status = 400;
      throw err;
    }

    const updated = await borrowsRepository.markReturnPending(
      borrowId,
      borrowerId,
    );
    if (!updated) {
      const err = new Error("Borrow is no longer eligible for return");
      err.status = 409;
      throw err;
    }

    return {
      message: borrow.return_before_passed
        ? "Return request submitted after the return-by date; waiting for owner confirmation"
        : "Return request submitted, waiting for owner confirmation",
    };
  }

  async confirmReturn(borrowId, ownerId) {
    const borrow = await borrowsRepository.findById(borrowId);
    if (!borrow) {
      const err = new Error("Borrow record not found");
      err.status = 404;
      throw err;
    }

    if (borrow.owner_id !== ownerId) {
      const err = new Error("Forbidden: You are not the owner of this asset");
      err.status = 403;
      throw err;
    }

    if (borrow.status === "returned_confirmed") {
      const err = new Error("This item has already been returned");
      err.status = 400;
      throw err;
    }

    if (borrow.status !== "returned_pending") {
      const err = new Error(
        "The borrower has not requested to return this item",
      );
      err.status = 400;
      throw err;
    }

    const result = await borrowsRepository.confirmReturn(
      borrowId,
      borrow.asset_id,
      borrow.borrower_id,
    );
    if (!result) {
      const err = new Error(
        "Return request is no longer awaiting confirmation",
      );
      err.status = 409;
      throw err;
    }

    return {
      message: "Return confirmed and asset is now ready for borrowing again",
      fine_amount: result.fine_amount,
      deposit_refunded: result.deposit_refunded,
    };
  }
}

module.exports = new BorrowService();
