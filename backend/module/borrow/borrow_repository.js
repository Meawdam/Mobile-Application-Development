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
    const [result] = await db.query(
      `
      INSERT INTO borrow (asset_id, borrower_id, borrow_date, status, payment_status)
      VALUES (?, ?, NULL, 'requested', 'unpaid')
    `,
      [asset_id, borrower_id],
    );
    return result.insertId;
  }

  async updateStatus(id, status, paymentStatus) {
    let sql = "UPDATE borrow SET status = ?";
    const params = [status];

    if (paymentStatus) {
      sql += ", payment_status = ?";
      params.push(paymentStatus);
    }

    if (status === "borrowed") {
      sql += ", borrow_date = CURRENT_DATE()";
    }

    if (status === "returned_confirmed") {
      sql += ", return_date = NOW()";
    }

    sql += " WHERE id = ?";
    params.push(id);

    const [result] = await db.query(sql, params);
    return result.affectedRows > 0;
  }

  async updateAssetStatus(assetId, status) {
    await db.query("UPDATE asset SET status = ? WHERE id = ?", [
      status,
      assetId,
    ]);
  }
}

module.exports = new BorrowRepository();
