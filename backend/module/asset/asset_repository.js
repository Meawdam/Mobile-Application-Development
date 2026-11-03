const db = require("../../db_config");

class AssetRepository {
  async findAllApproved(excludedOwnerId, searchTerm) {
    const ownerFilter =
      excludedOwnerId === undefined || excludedOwnerId === null
        ? ""
        : " AND owner_id <> ?";
    const params =
      excludedOwnerId === undefined || excludedOwnerId === null
        ? []
        : [excludedOwnerId];
    const searchFilter = searchTerm
      ? " AND (name LIKE ? OR description LIKE ? OR pickup_point LIKE ?)"
      : "";
    if (searchTerm) {
      const pattern = `%${searchTerm}%`;
      params.push(pattern, pattern, pattern);
    }
    const [rows] = await db.query(
      `SELECT * FROM asset
       WHERE approval = 'approved' AND status = 'ready'
         AND return_before >= CURRENT_DATE()${ownerFilter}${searchFilter}`,
      params,
    );
    return rows;
  }

  async findAll() {
    const [rows] = await db.query("SELECT * FROM asset ORDER BY id DESC");
    return rows;
  }

  async findById(id) {
    const [rows] = await db.query("SELECT * FROM asset WHERE id = ?", [id]);
    return rows[0];
  }

  async createAsset({
    owner_id,
    image,
    name,
    description,
    down_payment,
    price,
    pickup_point,
    return_before,
  }) {
    const [result] = await db.query(
      `INSERT INTO asset (
        owner_id, image, name, description, down_payment, price, pickup_point,
        return_before, status, approval
      )
        VALUES(?, ?, ?, ?, ?, ?, ?, ?, 'ready', 'pending')`,
      [
        owner_id,
        image,
        name,
        description,
        down_payment,
        price,
        pickup_point,
        return_before,
      ],
    );
    return result.insertId;
  }

  async updateApproval(id, approval, approvalMessage) {
    const [result] = await db.query(
        "UPDATE asset SET approval = ?, approval_message = ? WHERE id = ?",
        [approval, approvalMessage, id]
    );
    return result.affectedRows > 0;
  }

  async deleteAsset(id, ownerID) {
    const [result] = await db.query(
        "DELETE FROM asset WHERE id = ? AND owner_id = ?",
        [id, ownerID]
    );
    return result.affectedRows > 0;
  }
}

module.exports = new AssetRepository();
