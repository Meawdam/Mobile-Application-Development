const db = require("../../db_config");

class AssetRepository {
  async findAllApproved() {
    const [rows] = await db.query(
      "SELECT * FROM asset WHERE approval = 'approved' AND status = 'ready'",
    );
    return rows;
  }

  async findAll() {
    const [rows] = await db.query("SELECT * FROM asset ORDER BY id DESC");
    return rows;
  }

  async findById() {
    const [rows] = await db.query("SELECT * FROM asset WHERE id = ?", [id]);
    return rows[0];
  }

  async createAsset({owner_id, image, name, description, down_payment}) {
    const [result] = await db.query(
        `INSERT INTO asset (owner_id, image, name, description, down_payment, status, approval
        VALUES(?, ?, ?, ?, ?, 'ready', 'pending')`,
        [owner_id, image, name, description, down_payment]
    );
    return result.insertID;
  }

  async updateApproval(id, approval, approvalMessage) {
    const [result] = await db.query(
        "UPDATE asset SET approval = ?, approval_message = ? WHERE id = ?"
    );
    return result.affectedRows > 0;
  }

  async deleteAsset(id, ownerID) {
    const [result] = await db.query(
        "DELETE FROM asset WHERE id = ? AND owner_id = ?",
        [id, owner_id]
    );
    return result.affectedRows > 0;
  }
}

module.exports = new AssetRepository();
