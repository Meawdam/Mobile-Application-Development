const borrowsRepository = require("./borrow_repository");
const assetsRepository = require("../asset/asset_repository");

class BorrowService {
  async getAllBorrows() {
    return await borrowsRepository.findAll();
  }

  async getMyBorrows(borrowerId) {
    return await borrowsRepository.findByBorrowerId(borrowerId);
  }

  async requestBorrow(borrowerId, { asset_id }) {
    const asset = await assetsRepository.findById(asset_id);
    if (!asset) {
      const err = new Error("Asset not found");
      err.status = 404;
      throw err;
    }

    const returnBefore =
      asset.return_before instanceof Date
        ? [
            asset.return_before.getFullYear(),
            String(asset.return_before.getMonth() + 1).padStart(2, "0"),
            String(asset.return_before.getDate()).padStart(2, "0"),
          ].join("-")
        : asset.return_before;
    const parsedReturnBefore =
      typeof returnBefore === "string" &&
      /^\d{4}-\d{2}-\d{2}$/.test(returnBefore)
        ? new Date(`${returnBefore}T00:00:00.000Z`)
        : null;

    if (
      !parsedReturnBefore ||
      Number.isNaN(parsedReturnBefore.getTime()) ||
      parsedReturnBefore.toISOString().slice(0, 10) !== returnBefore
    ) {
      const err = new Error("The asset does not have a valid return date");
      err.status = 400;
      throw err;
    }

    if (returnBefore < new Date().toISOString().slice(0, 10)) {
      const err = new Error("The asset return date has passed");
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

    const borrowId = await borrowsRepository.createBorrow({
      asset_id,
      borrower_id: borrowerId,
    });

    return {
      id: borrowId,
      asset_id,
      status: "requested",
      payment_status: "unpaid",
    };
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

    await borrowsRepository.updateStatus(borrowId, "borrowed", "paid");
    await borrowsRepository.updateAssetStatus(borrow.asset_id, "borrowed");

    return { message: "Payment completed and asset borrowed successfully" };
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

    if (borrow.return_before_passed) {
      const err = new Error("The asset return date has passed");
      err.status = 400;
      throw err;
    }

    await borrowsRepository.updateStatus(borrowId, "returned_pending", null);
    return {
      message: "Return request submitted, waiting for owner confirmation",
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

    await borrowsRepository.updateStatus(
      borrowId,
      "returned_confirmed",
      "refunded",
    );
    await borrowsRepository.updateAssetStatus(borrow.asset_id, "ready");

    return {
      message: "Return confirmed and asset is now ready for borrowing again",
    };
  }
}

module.exports = new BorrowService();
