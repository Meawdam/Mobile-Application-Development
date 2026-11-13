const db = require("../../db_config");
const {
  logActivities,
  borrowActivityEntries,
} = require("../../utils/activity_logger");

class BorrowRepository {
  async findAll() {
    const [rows] = await db.query(`
      SELECT 
        b.id, b.pickup_date, b.planned_return_date, b.rental_days,
        b.rental_amount, b.deposit_amount, b.total_amount,
        b.borrow_date, b.return_date, b.status, b.payment_status,
        b.fine_amount,
        a.id AS asset_id, a.name AS asset_name, a.image AS asset_image,
        a.down_payment, a.price AS price_per_day, a.return_before AS lending_end_date,
        a.pickup_point,
        u.id AS borrower_id, u.username AS borrower_name, u.email AS borrower_email,
        owner.username AS owner_name
      FROM borrow b
      JOIN asset a ON b.asset_id = a.id
      JOIN users u ON b.borrower_id = u.id
      JOIN users owner ON a.owner_id = owner.id
      ORDER BY b.created_at DESC
    `);
    return rows;
  }

  async findByBorrowerId(borrowerId) {
    const [rows] = await db.query(
      `
      SELECT 
        b.id, b.pickup_date, b.planned_return_date, b.rental_days,
        b.rental_amount, b.deposit_amount, b.total_amount,
        b.borrow_date, b.return_date, b.status, b.payment_status,
        b.fine_amount,
        a.id AS asset_id, a.name AS asset_name, a.image AS asset_image,
        a.description, a.down_payment, a.price AS price_per_day,
        a.return_before AS lending_end_date, a.pickup_point,
        owner.username AS owner_name,
        borrower.username AS borrower_name
      FROM borrow b
      JOIN asset a ON b.asset_id = a.id
      JOIN users owner ON a.owner_id = owner.id
      JOIN users borrower ON b.borrower_id = borrower.id
      WHERE b.borrower_id = ?
      ORDER BY b.created_at DESC
    `,
      [borrowerId],
    );
    return rows;
  }

  async findByOwnerId(ownerId) {
    const [rows] = await db.query(
      `
      SELECT 
        b.id, b.pickup_date, b.planned_return_date, b.rental_days,
        b.rental_amount, b.deposit_amount, b.total_amount,
        b.borrow_date, b.return_date, b.status, b.payment_status,
        b.fine_amount,
        a.id AS asset_id, a.name AS asset_name, a.image AS asset_image,
        a.description, a.down_payment, a.price AS price_per_day,
        a.return_before AS lending_end_date, a.pickup_point,
        owner.username AS owner_name,
        borrower.username AS borrower_name
      FROM borrow b
      JOIN asset a ON b.asset_id = a.id
      JOIN users owner ON a.owner_id = owner.id
      JOIN users borrower ON b.borrower_id = borrower.id
      WHERE a.owner_id = ?
      ORDER BY b.created_at DESC
    `,
      [ownerId],
    );
    return rows;
  }

  async findById(id) {
    const [rows] = await db.query(
      `
      SELECT b.*, a.owner_id, a.return_before, a.name AS asset_name,
        a.image AS asset_image, a.pickup_point, a.price AS price_per_day,
        a.return_before AS lending_end_date,
        a.return_before < CURRENT_DATE() AS return_before_passed,
        owner.username AS owner_name,
        borrower.username AS borrower_name
      FROM borrow b
      JOIN asset a ON b.asset_id = a.id
      JOIN users owner ON a.owner_id = owner.id
      JOIN users borrower ON b.borrower_id = borrower.id
      WHERE b.id = ?
    `,
      [id],
    );
    return rows[0];
  }

  async createBorrow({
    asset_id,
    borrower_id,
    owner_id,
    pickup_date,
    planned_return_date,
    rental_days,
    rental_amount,
    deposit_amount,
    total_amount,
  }) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [assetResult] = await connection.query(
        `SELECT id FROM asset
         WHERE id = ? AND owner_id <> ? AND status = 'ready'
           AND approval = 'approved' AND return_before >= ?
         FOR UPDATE`,
        [asset_id, borrower_id, planned_return_date],
      );

      if (assetResult.length === 0) {
        const err = new Error("Asset is no longer available for borrowing");
        err.status = 409;
        throw err;
      }

      const [activeBorrows] = await connection.query(
        `SELECT id FROM borrow
         WHERE asset_id = ?
           AND status IN ('requested', 'approved', 'borrowed', 'returned_pending')
         LIMIT 1`,
        [asset_id],
      );
      if (activeBorrows.length > 0) {
        const err = new Error("Asset already has an active borrow request");
        err.status = 409;
        throw err;
      }

      const [result] = await connection.query(
        `INSERT INTO borrow (
          asset_id, borrower_id, pickup_date, planned_return_date, rental_days,
          rental_amount, deposit_amount, total_amount,
          borrow_date, status, payment_status, fine_amount
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL, 'requested', 'unpaid', 0)`,
        [
          asset_id,
          borrower_id,
          pickup_date,
          planned_return_date,
          rental_days,
          rental_amount,
          deposit_amount,
          total_amount,
        ],
      );
      const borrowId = result.insertId;
      await logActivities(
        borrowActivityEntries({
          borrowerId: borrower_id,
          ownerId: owner_id,
          actorId: borrower_id,
          action: "borrow_requested",
          message: "Borrow request submitted",
          borrowId,
          details: { asset_id: Number(asset_id) },
        }),
        connection,
      );
      await connection.commit();
      return borrowId;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async markBorrowed(id, borrowerId, assetId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [borrows] = await connection.query(
        `SELECT b.id, b.total_amount, b.rental_amount, b.deposit_amount,
          b.status, b.payment_status, a.owner_id
         FROM borrow b
         JOIN asset a ON a.id = b.asset_id
         WHERE b.id = ? AND b.borrower_id = ?
         FOR UPDATE`,
        [id, borrowerId],
      );
      if (borrows.length === 0) {
        const err = new Error("Borrow record not found");
        err.status = 404;
        throw err;
      }
      const borrow = borrows[0];
      if (
        !["requested", "approved"].includes(borrow.status) ||
        borrow.payment_status !== "unpaid"
      ) {
        await connection.rollback();
        return false;
      }

      const totalAmount = Number(borrow.total_amount);
      const [users] = await connection.query(
        `SELECT wallet_balance FROM users WHERE id = ? FOR UPDATE`,
        [borrowerId],
      );
      if (users.length === 0) {
        const err = new Error("User not found");
        err.status = 404;
        throw err;
      }

      const balance = Number(users[0].wallet_balance);
      if (balance < totalAmount) {
        const err = new Error("Insufficient wallet balance");
        err.status = 400;
        throw err;
      }

      const [assets] = await connection.query(
        `SELECT a.id FROM asset a
         JOIN borrow b ON b.asset_id = a.id
         WHERE a.id = ? AND b.id = ? AND a.status = 'ready'
           AND a.approval = 'approved'
           AND a.return_before >= CURRENT_DATE()
           AND a.return_before >= b.planned_return_date
         FOR UPDATE`,
        [assetId, id],
      );
      if (assets.length === 0) {
        const err = new Error("Asset is no longer available for borrowing");
        err.status = 409;
        throw err;
      }

      await connection.query(
        `UPDATE users SET wallet_balance = wallet_balance - ? WHERE id = ?`,
        [totalAmount, borrowerId],
      );

      const [borrowResult] = await connection.query(
        `UPDATE borrow
         SET status = 'borrowed', payment_status = 'paid',
             borrow_date = COALESCE(pickup_date, CURRENT_DATE())
         WHERE id = ? AND borrower_id = ? AND status IN ('requested', 'approved')
           AND payment_status = 'unpaid'`,
        [id, borrowerId],
      );
      if (borrowResult.affectedRows === 0) {
        await connection.rollback();
        return false;
      }

      const [assetResult] = await connection.query(
        `UPDATE asset SET status = 'borrowed'
         WHERE id = ? AND status = 'ready' AND return_before >= CURRENT_DATE()`,
        [assetId],
      );
      if (assetResult.affectedRows === 0) {
        const err = new Error("Reserved asset is no longer available");
        err.status = 409;
        throw err;
      }

      const [updatedWallet] = await connection.query(
        `SELECT wallet_balance FROM users WHERE id = ?`,
        [borrowerId],
      );

      await connection.query(
        `INSERT INTO financial_transactions
          (user_id, actor_id, borrow_id, transaction_type, amount, status, description)
         VALUES (?, ?, ?, 'rental_payment', ?, 'completed', 'Rental payment')`,
        [borrowerId, borrowerId, id, Number(borrow.rental_amount)],
      );
      await connection.query(
        `INSERT INTO financial_transactions
          (user_id, actor_id, borrow_id, transaction_type, amount, status, description)
         VALUES (?, ?, ?, 'deposit_hold', ?, 'pending', 'Deposit held')`,
        [borrowerId, borrowerId, id, Number(borrow.deposit_amount)],
      );
      await logActivities(
        borrowActivityEntries({
          borrowerId,
          ownerId: Number(borrow.owner_id),
          actorId: borrowerId,
          action: "payment_completed",
          message: "Borrow payment completed",
          borrowId: id,
          details: { total_amount: totalAmount },
        }),
        connection,
      );

      await connection.commit();
      return {
        paid: true,
        total_amount: totalAmount,
        wallet_balance: Number(updatedWallet[0].wallet_balance),
      };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async cancelRequest(id, borrowerId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [borrows] = await connection.query(
        `SELECT b.id, b.status, b.payment_status, a.owner_id
         FROM borrow b
         JOIN asset a ON a.id = b.asset_id
         WHERE b.id = ? AND b.borrower_id = ?
         FOR UPDATE`,
        [id, borrowerId],
      );
      if (
        borrows.length === 0 ||
        !["requested", "approved"].includes(borrows[0].status) ||
        borrows[0].payment_status !== "unpaid"
      ) {
        await connection.rollback();
        return false;
      }

      await connection.query(
        `UPDATE borrow SET status = 'rejected'
         WHERE id = ? AND borrower_id = ? AND status IN ('requested', 'approved')
           AND payment_status = 'unpaid'`,
        [id, borrowerId],
      );
      await logActivities(
        borrowActivityEntries({
          borrowerId,
          ownerId: Number(borrows[0].owner_id),
          actorId: borrowerId,
          action: "borrow_cancelled",
          message: "Borrow request cancelled",
          borrowId: id,
        }),
        connection,
      );
      await connection.commit();
      return true;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async decideRequest(id, ownerId, decision, reason) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [borrows] = await connection.query(
        `SELECT b.id, b.borrower_id, b.status, b.payment_status, a.owner_id
         FROM borrow b
         JOIN asset a ON a.id = b.asset_id
         WHERE b.id = ? AND a.owner_id = ?
         FOR UPDATE`,
        [id, ownerId],
      );
      if (borrows.length === 0) {
        await connection.rollback();
        return null;
      }
      const borrow = borrows[0];
      const eligibleStatus = decision === "approve"
        ? borrow.status === "requested"
        : ["requested", "approved"].includes(borrow.status);
      if (!eligibleStatus || borrow.payment_status !== "unpaid") {
        await connection.rollback();
        return false;
      }

      const nextStatus = decision === "approve" ? "approved" : "rejected";
      await connection.query(
        `UPDATE borrow SET status = ?
         WHERE id = ? AND status IN ('requested', 'approved')
           AND payment_status = 'unpaid'`,
        [nextStatus, id],
      );
      await logActivities(
        borrowActivityEntries({
          borrowerId: Number(borrow.borrower_id),
          ownerId,
          actorId: ownerId,
          action: decision === "approve" ? "borrow_approved" : "borrow_rejected",
          message: decision === "approve"
            ? "Borrow request approved"
            : "Borrow request rejected",
          borrowId: id,
          details: decision === "reject" ? { reason } : undefined,
        }),
        connection,
      );
      await connection.commit();
      return { id: Number(id), status: nextStatus };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async markReturnPending(id, borrowerId, ownerId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [result] = await connection.query(
        `UPDATE borrow SET status = 'returned_pending'
         WHERE id = ? AND borrower_id = ? AND status = 'borrowed'`,
        [id, borrowerId],
      );
      if (result.affectedRows === 0) {
        await connection.rollback();
        return false;
      }
      await logActivities(
        borrowActivityEntries({
          borrowerId,
          ownerId,
          actorId: borrowerId,
          action: "return_requested",
          message: "Return requested",
          borrowId: id,
        }),
        connection,
      );
      await connection.commit();
      return true;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async confirmReturn(id, assetId, borrowerId, ownerId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [assets] = await connection.query(
        `SELECT id, GREATEST(DATEDIFF(CURRENT_DATE(), return_before), 0) * price
           AS fine_amount
         FROM asset WHERE id = ? AND status = 'borrowed' FOR UPDATE`,
        [assetId],
      );
      if (assets.length === 0) {
        const err = new Error("Borrowed asset is no longer available");
        err.status = 409;
        throw err;
      }

      const [borrows] = await connection.query(
        `SELECT id, borrower_id, deposit_amount, status
         FROM borrow WHERE id = ? FOR UPDATE`,
        [id],
      );
      if (borrows.length === 0 || borrows[0].status !== "returned_pending") {
        await connection.rollback();
        return false;
      }

      const fineAmount = Number(assets[0].fine_amount);
      const depositAmount = Number(borrows[0].deposit_amount);
      const refundAmount = Math.max(depositAmount - fineAmount, 0);

      const [borrowResult] = await connection.query(
        `UPDATE borrow
         SET status = 'returned_confirmed',
             payment_status = IF(? = 0, 'refunded', payment_status),
             return_date = NOW(), fine_amount = ?
         WHERE id = ? AND status = 'returned_pending'`,
        [refundAmount, fineAmount, id],
      );
      if (borrowResult.affectedRows === 0) {
        await connection.rollback();
        return false;
      }

      const [assetResult] = await connection.query(
        "UPDATE asset SET status = 'ready' WHERE id = ? AND status = 'borrowed'",
        [assetId],
      );
      if (assetResult.affectedRows === 0) {
        const err = new Error("Borrowed asset is no longer available");
        err.status = 409;
        throw err;
      }

      if (refundAmount === 0) {
        await connection.query(
          `UPDATE financial_transactions
           SET status = 'released', processed_at = NOW()
           WHERE borrow_id = ? AND transaction_type = 'deposit_hold'
             AND status = 'pending'`,
          [id],
        );
      }
      if (fineAmount > 0) {
        await connection.query(
          `INSERT INTO financial_transactions
            (user_id, actor_id, borrow_id, transaction_type, amount, status,
             description, processed_at)
           VALUES (?, ?, ?, 'fine_collected', ?, 'completed',
             'Late return fine', NOW())`,
          [borrowerId, ownerId, id, fineAmount],
        );
      }

      let refundTransactionId = null;
      if (refundAmount > 0) {
        const [refund] = await connection.query(
          `INSERT INTO financial_transactions
            (user_id, actor_id, borrow_id, transaction_type, amount, status,
             description)
           VALUES (?, ?, ?, 'deposit_refund', ?, 'pending',
             'Deposit refund awaiting admin processing')`,
          [borrowerId, ownerId, id, refundAmount],
        );
        refundTransactionId = refund.insertId;
      }

      await logActivities(
        borrowActivityEntries({
          borrowerId,
          ownerId,
          actorId: ownerId,
          action: "return_confirmed",
          message: refundAmount > 0
            ? "Return confirmed; refund awaiting admin processing"
            : "Return confirmed; no deposit refund due",
          borrowId: id,
          details: {
            fine_amount: fineAmount,
            deposit_refund_pending: refundAmount,
          },
        }),
        connection,
      );

      await connection.commit();
      return {
        fine_amount: fineAmount,
        deposit_refunded: 0,
        refund_pending: refundAmount,
        refund_transaction_id: refundTransactionId,
      };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }
}

module.exports = new BorrowRepository();
