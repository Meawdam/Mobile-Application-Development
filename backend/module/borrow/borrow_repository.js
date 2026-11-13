const db = require("../../db_config");
const {
  logActivities,
  borrowActivityEntries,
} = require("../../utils/activity_logger");
const {
  MAX_STORED_AMOUNT_CENTS,
  amountCentsToNumber,
  formatAmountCents,
  parseAmountCents,
} = require("../../utils/money_utils");

class BorrowRepository {
  async findAll() {
    const [rows] = await db.query(`
      SELECT 
        b.id, b.pickup_date, b.planned_return_date, b.rental_days,
        b.rental_amount, b.deposit_amount, b.total_amount,
        b.borrow_date, b.return_date, b.status, b.payment_status,
        a.id AS asset_id, a.name AS asset_name, a.image AS asset_image,
        b.deposit_amount AS down_payment,
        b.rental_amount / NULLIF(b.rental_days, 0) AS price_per_day,
        a.return_before AS lending_end_date,
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
        a.id AS asset_id, a.name AS asset_name, a.image AS asset_image,
        a.description, b.deposit_amount AS down_payment,
        b.rental_amount / NULLIF(b.rental_days, 0) AS price_per_day,
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
        a.id AS asset_id, a.name AS asset_name, a.image AS asset_image,
        a.description, b.deposit_amount AS down_payment,
        b.rental_amount / NULLIF(b.rental_days, 0) AS price_per_day,
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
        a.image AS asset_image, a.pickup_point,
        b.deposit_amount AS down_payment,
        b.rental_amount / NULLIF(b.rental_days, 0) AS price_per_day,
        a.return_before AS lending_end_date,
        b.planned_return_date < CURRENT_DATE() AS return_deadline_passed,
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
          borrow_date, status, payment_status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL, 'requested', 'unpaid')`,
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

      const totalAmountCents = parseAmountCents(borrow.total_amount);
      const rentalAmountCents = parseAmountCents(borrow.rental_amount);
      const depositAmountCents = parseAmountCents(borrow.deposit_amount);
      if (
        totalAmountCents === null ||
        rentalAmountCents === null ||
        depositAmountCents === null ||
        totalAmountCents > MAX_STORED_AMOUNT_CENTS ||
        !Number.isSafeInteger(rentalAmountCents + depositAmountCents) ||
        totalAmountCents !== rentalAmountCents + depositAmountCents
      ) {
        throw new Error(`Invalid monetary data for borrow ${id}`);
      }

      const totalAmount = formatAmountCents(totalAmountCents);
      const [users] = await connection.query(
        `SELECT wallet_balance FROM users WHERE id = ? FOR UPDATE`,
        [borrowerId],
      );
      if (users.length === 0) {
        const err = new Error("User not found");
        err.status = 404;
        throw err;
      }

      const balanceCents = parseAmountCents(users[0].wallet_balance);
      if (balanceCents === null) {
        throw new Error(`Invalid wallet balance for user ${borrowerId}`);
      }
      if (balanceCents < totalAmountCents) {
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
        [
          borrowerId,
          borrowerId,
          id,
          formatAmountCents(rentalAmountCents),
        ],
      );
      await connection.query(
        `INSERT INTO financial_transactions
          (user_id, actor_id, borrow_id, transaction_type, amount, status, description)
         VALUES (?, ?, ?, 'deposit_hold', ?, 'pending', 'Deposit held')`,
        [
          borrowerId,
          borrowerId,
          id,
          formatAmountCents(depositAmountCents),
        ],
      );
      await logActivities(
        borrowActivityEntries({
          borrowerId,
          ownerId: Number(borrow.owner_id),
          actorId: borrowerId,
          action: "payment_completed",
          message: "Borrow payment completed",
          borrowId: id,
          details: { total_amount: amountCentsToNumber(totalAmountCents) },
        }),
        connection,
      );

      await connection.commit();
      return {
        paid: true,
        total_amount: amountCentsToNumber(totalAmountCents),
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

  async _forfeitDeposit(connection, borrow) {
    if (
      borrow.payment_status !== "paid" ||
      !["borrowed", "returned_pending"].includes(borrow.status)
    ) {
      return false;
    }

    const [holds] = await connection.query(
      `SELECT id, amount FROM financial_transactions
       WHERE borrow_id = ? AND transaction_type = 'deposit_hold'
         AND status = 'pending'
       FOR UPDATE`,
      [borrow.id],
    );
    if (holds.length === 0) {
      throw new Error(`Pending deposit hold missing for borrow ${borrow.id}`);
    }

    const amountCents = parseAmountCents(holds[0].amount);
    const depositCents = parseAmountCents(borrow.deposit_amount);
    if (amountCents === null || amountCents !== depositCents) {
      throw new Error(`Deposit amount mismatch for borrow ${borrow.id}`);
    }

    const [updatedBorrow] = await connection.query(
      `UPDATE borrow SET payment_status = 'forfeited'
       WHERE id = ? AND payment_status = 'paid'
         AND status IN ('borrowed', 'returned_pending')`,
      [borrow.id],
    );
    if (updatedBorrow.affectedRows === 0) {
      return false;
    }

    const ownerId = Number(borrow.owner_id);
    const [owners] = await connection.query(
      "SELECT id, wallet_balance FROM users WHERE id = ? FOR UPDATE",
      [ownerId],
    );
    if (owners.length === 0) {
      throw new Error(`Asset owner missing for borrow ${borrow.id}`);
    }
    const ownerBalanceCents = parseAmountCents(owners[0].wallet_balance);
    if (
      ownerBalanceCents === null ||
      ownerBalanceCents + amountCents > MAX_STORED_AMOUNT_CENTS
    ) {
      const err = new Error("Asset owner's wallet balance exceeds the supported range");
      err.status = 409;
      throw err;
    }

    await connection.query(
      "UPDATE users SET wallet_balance = wallet_balance + ? WHERE id = ?",
      [formatAmountCents(amountCents), ownerId],
    );
    const [releasedHold] = await connection.query(
      `UPDATE financial_transactions
       SET status = 'released', processed_at = NOW()
       WHERE id = ? AND status = 'pending'`,
      [holds[0].id],
    );
    if (releasedHold.affectedRows === 0) {
      throw new Error(`Deposit hold changed for borrow ${borrow.id}`);
    }

    await connection.query(
      `INSERT INTO financial_transactions
        (user_id, borrow_id, transaction_type, amount, status,
         description, processed_at)
       VALUES (?, ?, 'deposit_forfeiture', ?, 'completed',
         'Deposit forfeited and credited to asset owner', NOW())`,
      [ownerId, borrow.id, formatAmountCents(amountCents)],
    );
    await logActivities(
      [
        {
          userId: Number(borrow.borrower_id),
          category: "finance",
          action: "deposit_forfeited",
          entityType: "borrow",
          entityId: Number(borrow.id),
          message: "Deposit forfeited after the return deadline",
          details: { amount: amountCentsToNumber(amountCents), owner_id: ownerId },
        },
        {
          userId: ownerId,
          category: "finance",
          action: "deposit_forfeited",
          entityType: "borrow",
          entityId: Number(borrow.id),
          message: "Overdue deposit credited to asset owner",
          details: {
            amount: amountCentsToNumber(amountCents),
            borrower_id: Number(borrow.borrower_id),
          },
        },
      ],
      connection,
    );
    return true;
  }

  async forfeitOverdueDeposits() {
    let totalForfeited = 0;
    const batchSize = 100;

    while (true) {
      const connection = await db.getConnection();
      try {
        await connection.beginTransaction();
        const [borrows] = await connection.query(
          `SELECT b.id, b.borrower_id, b.deposit_amount, b.status,
             b.payment_status, a.owner_id
           FROM borrow b
           JOIN asset a ON a.id = b.asset_id
           WHERE b.payment_status = 'paid'
             AND b.status IN ('borrowed', 'returned_pending')
             AND b.planned_return_date < CURRENT_DATE()
           ORDER BY b.id
           LIMIT ?
           FOR UPDATE`,
          [batchSize],
        );

        for (const borrow of borrows) {
          if (await this._forfeitDeposit(connection, borrow)) {
            totalForfeited += 1;
          }
        }
        await connection.commit();
        if (borrows.length < batchSize) {
          return totalForfeited;
        }
      } catch (error) {
        await connection.rollback();
        throw error;
      } finally {
        connection.release();
      }
    }
  }

  async markReturnPending(id, borrowerId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [borrows] = await connection.query(
        `SELECT b.id, b.borrower_id, b.deposit_amount, b.status,
          b.payment_status, b.planned_return_date,
          b.planned_return_date < CURRENT_DATE() AS return_deadline_passed,
          a.owner_id
         FROM borrow b
         JOIN asset a ON a.id = b.asset_id
         WHERE b.id = ? AND b.borrower_id = ?
         FOR UPDATE`,
        [id, borrowerId],
      );
      if (borrows.length === 0 || borrows[0].status !== "borrowed") {
        await connection.rollback();
        return false;
      }

      const borrow = borrows[0];
      let paymentStatus = borrow.payment_status;
      if (borrow.return_deadline_passed && borrow.payment_status === "paid") {
        const forfeited = await this._forfeitDeposit(connection, borrow);
        if (!forfeited) {
          await connection.rollback();
          return false;
        }
        paymentStatus = "forfeited";
      }

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
          ownerId: Number(borrow.owner_id),
          actorId: borrowerId,
          action: "return_requested",
          message: "Return requested",
          borrowId: id,
        }),
        connection,
      );
      await connection.commit();
      return { payment_status: paymentStatus };
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
      const [borrows] = await connection.query(
        `SELECT b.id, b.borrower_id, b.deposit_amount, b.status,
          b.payment_status, b.planned_return_date,
          b.planned_return_date < CURRENT_DATE() AS return_deadline_passed,
          a.owner_id, a.status AS asset_status
         FROM borrow b
         JOIN asset a ON a.id = b.asset_id
         WHERE b.id = ? AND b.asset_id = ?
         FOR UPDATE`,
        [id, assetId],
      );
      if (borrows.length === 0 || borrows[0].asset_status !== "borrowed") {
        const err = new Error("Borrowed asset is no longer available");
        err.status = 409;
        throw err;
      }

      const borrow = borrows[0];
      if (borrow.status !== "returned_pending") {
        await connection.rollback();
        return false;
      }

      if (borrow.return_deadline_passed && borrow.payment_status === "paid") {
        const forfeited = await this._forfeitDeposit(connection, borrow);
        if (!forfeited) {
          await connection.rollback();
          return false;
        }
        borrow.payment_status = "forfeited";
      }

      const depositAmountCents = parseAmountCents(borrow.deposit_amount);
      if (depositAmountCents === null) {
        throw new Error(`Invalid deposit amount for borrow ${id}`);
      }
      const depositForfeitedCents =
        borrow.payment_status === "forfeited" ? depositAmountCents : 0;
      const refundAmountCents =
        borrow.payment_status === "paid" ? depositAmountCents : 0;
      const nextPaymentStatus =
        refundAmountCents === 0 && borrow.payment_status === "paid"
          ? "refunded"
          : borrow.payment_status;

      const [borrowResult] = await connection.query(
        `UPDATE borrow
         SET status = 'returned_confirmed', payment_status = ?,
             return_date = NOW()
         WHERE id = ? AND status = 'returned_pending'`,
        [nextPaymentStatus, id],
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

      if (refundAmountCents === 0 && depositForfeitedCents === 0) {
        await connection.query(
          `UPDATE financial_transactions
           SET status = 'released', processed_at = NOW()
           WHERE borrow_id = ? AND transaction_type = 'deposit_hold'
             AND status = 'pending'`,
          [id],
        );
      }

      let refundTransactionId = null;
      if (refundAmountCents > 0) {
        const [refund] = await connection.query(
          `INSERT INTO financial_transactions
            (user_id, actor_id, borrow_id, transaction_type, amount, status,
             description)
           VALUES (?, ?, ?, 'deposit_refund', ?, 'pending',
             'Deposit refund awaiting admin processing')`,
          [
            borrowerId,
            ownerId,
            id,
            formatAmountCents(refundAmountCents),
          ],
        );
        refundTransactionId = refund.insertId;
      }

      await logActivities(
        borrowActivityEntries({
          borrowerId,
          ownerId,
          actorId: ownerId,
          action: "return_confirmed",
          message: refundAmountCents > 0
            ? "Return confirmed; deposit refund awaiting admin processing"
            : depositForfeitedCents > 0
              ? "Return confirmed; deposit was forfeited"
              : "Return confirmed; no deposit refund due",
          borrowId: id,
          details: {
            deposit_forfeited: amountCentsToNumber(depositForfeitedCents),
            deposit_refund_pending: amountCentsToNumber(refundAmountCents),
          },
        }),
        connection,
      );

      await connection.commit();
      return {
        deposit_forfeited: amountCentsToNumber(depositForfeitedCents),
        refund_pending: amountCentsToNumber(refundAmountCents),
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
