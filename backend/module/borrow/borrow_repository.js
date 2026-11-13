const db = require("../../db_config");

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
      await connection.commit();
      return result.insertId;
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
        `SELECT id, total_amount, status, payment_status
         FROM borrow
         WHERE id = ? AND borrower_id = ?
         FOR UPDATE`,
        [id, borrowerId],
      );
      if (borrows.length === 0) {
        const err = new Error("Borrow record not found");
        err.status = 404;
        throw err;
      }
      const borrow = borrows[0];
      if (borrow.status !== "requested" || borrow.payment_status !== "unpaid") {
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
        `SELECT id FROM asset
         WHERE id = ? AND status = 'ready' AND approval = 'approved'
           AND return_before >= CURRENT_DATE()
         FOR UPDATE`,
        [assetId],
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
         WHERE id = ? AND borrower_id = ? AND status = 'requested'
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
    const [result] = await db.query(
      `UPDATE borrow SET status = 'rejected'
       WHERE id = ? AND borrower_id = ? AND status = 'requested'
         AND payment_status = 'unpaid'`,
      [id, borrowerId],
    );
    return result.affectedRows > 0;
  }

  async markReturnPending(id, borrowerId) {
    const [result] = await db.query(
      `UPDATE borrow SET status = 'returned_pending'
       WHERE id = ? AND borrower_id = ? AND status = 'borrowed'`,
      [id, borrowerId],
    );
    return result.affectedRows > 0;
  }

  async confirmReturn(id, assetId, borrowerId) {
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
        `SELECT id, deposit_amount, status
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
         SET status = 'returned_confirmed', payment_status = 'refunded',
             return_date = NOW(), fine_amount = ?
         WHERE id = ? AND status = 'returned_pending'`,
        [fineAmount, id],
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

      if (refundAmount > 0) {
        await connection.query(
          `UPDATE users SET wallet_balance = wallet_balance + ? WHERE id = ?`,
          [refundAmount, borrowerId],
        );
      }

      await connection.commit();
      return {
        fine_amount: fineAmount,
        deposit_refunded: refundAmount,
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
