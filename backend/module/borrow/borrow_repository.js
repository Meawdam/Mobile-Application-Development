const db= require("../../db_config");

class BorrowRepository {

  async findAll() {
    const [rows] = await db.query(`
      SELECT 
        b.id, b.borrow_date, b.return_date, b.status, b.payment_status,
        a.id AS asset_id, a.name AS asset_name, a.image AS asset_image,
        a.down_payment, a.return_before,
        u.id AS borrower_id, u.username AS borrower_name, u.email AS borrower_email,
        owner.username AS owner_name
      FROM borrow b
      JOIN asset a ON b.asset_id = a.id
      JOIN users u ON b.borrower_id = u.id
      JOIN users owner ON a.owner_id = owner.id
      ORDER BY b.borrow_date DESC
    `);
    return rows;
  }


  async findByBorrowerId(borrowerId) {
    const [rows] = await db.query(
      `
      SELECT 
        b.id, b.borrow_date, b.return_date, b.status, b.payment_status,
        a.id AS asset_id, a.name AS asset_name, a.image AS asset_image,
        a.description, a.down_payment, a.return_before,
        owner.username AS owner_name
      FROM borrow b
      JOIN asset a ON b.asset_id = a.id
      JOIN users owner ON a.owner_id = owner.id
      WHERE b.borrower_id = ?
      ORDER BY b.borrow_date DESC
    `,
      [borrowerId],
    );
    return rows;
  }

  async findById(id) {
    const [rows] = await db.query(
      `
      SELECT b.*, a.owner_id, a.return_before,
        a.return_before < CURRENT_DATE() AS return_before_passed
      FROM borrow b
      JOIN asset a ON b.asset_id = a.id
      WHERE b.id = ?
    `,
      [id],
    );
    return rows[0];
  }

  async createBorrow({ asset_id, borrower_id }) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [assetResult] = await connection.query(
        `SELECT id FROM asset
         WHERE id = ? AND owner_id <> ? AND status = 'ready'
           AND approval = 'approved' AND return_before >= CURRENT_DATE()
         FOR UPDATE`,
        [asset_id, borrower_id],
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
          asset_id, borrower_id, borrow_date, status, payment_status
        ) VALUES (?, ?, NULL, 'requested', 'unpaid')`,
        [asset_id, borrower_id],
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

      const [borrowResult] = await connection.query(
        `UPDATE borrow
         SET status = 'borrowed', payment_status = 'paid',
             borrow_date = CURRENT_DATE()
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

      await connection.commit();
      return true;
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

  async confirmReturn(id, assetId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [assets] = await connection.query(
        "SELECT id FROM asset WHERE id = ? AND status = 'borrowed' FOR UPDATE",
        [assetId],
      );
      if (assets.length === 0) {
        const err = new Error("Borrowed asset is no longer available");
        err.status = 409;
        throw err;
      }

      const [borrowResult] = await connection.query(
        `UPDATE borrow
         SET status = 'returned_confirmed', payment_status = 'refunded',
             return_date = NOW()
         WHERE id = ? AND status = 'returned_pending'`,
        [id],
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

      await connection.commit();
      return true;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

}

module.exports = new BorrowRepository();
