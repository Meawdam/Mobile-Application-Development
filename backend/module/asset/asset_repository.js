const db = require("../../db_config");

class AssetRepository {
  async findAllApproved(excludedOwnerId, searchTerm) {
    const ownerFilter =
      excludedOwnerId === undefined || excludedOwnerId === null
        ? ""
        : " AND a.owner_id <> ?";
    const params =
      excludedOwnerId === undefined || excludedOwnerId === null
        ? []
        : [excludedOwnerId];
    const searchFilter = searchTerm
      ? " AND (a.name LIKE ? OR a.description LIKE ? OR a.pickup_point LIKE ?)"
      : "";
    if (searchTerm) {
      const pattern = `%${searchTerm}%`;
      params.push(pattern, pattern, pattern);
    }
    const [rows] = await db.query(
      `SELECT a.*, u.username AS owner_username
       FROM asset a
       LEFT JOIN users u ON u.id = a.owner_id
       WHERE a.approval = 'approved' AND a.status = 'ready'
         AND a.return_before >= CURRENT_DATE()${ownerFilter}${searchFilter}
       ORDER BY a.id DESC`,
      params,
    );
    return rows;
  }

  async findAll() {
    const [rows] = await db.query(
      `SELECT a.*, u.username AS owner_username
       FROM asset a
       LEFT JOIN users u ON u.id = a.owner_id
       ORDER BY a.id DESC`,
    );
    return rows;
  }

  async findByOwnerId(ownerId) {
    const [rows] = await db.query(
      `SELECT a.*, u.username AS owner_username
       FROM asset a
       LEFT JOIN users u ON u.id = a.owner_id
       WHERE a.owner_id = ?
       ORDER BY a.id DESC`,
      [ownerId],
    );
    return rows;
  }

  async findById(id) {
    const [rows] = await db.query(
      `SELECT a.*, u.username AS owner_username
       FROM asset a
       LEFT JOIN users u ON u.id = a.owner_id
       WHERE a.id = ?`,
      [id],
    );
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

  async updateAsset(id, ownerId, data) {
    const [result] = await db.query(
      `UPDATE asset
       SET name = ?, description = ?, down_payment = ?, price = ?,
           pickup_point = ?, return_before = ?
       WHERE id = ? AND owner_id = ?`,
      [
        data.name,
        data.description,
        data.down_payment,
        data.price,
        data.pickup_point,
        data.return_before,
        id,
        ownerId,
      ],
    );
    return result.affectedRows > 0;
  }

  async updateApproval(id, approval, approvalMessage) {
    const [result] = await db.query(
      "UPDATE asset SET approval = ?, approval_message = ? WHERE id = ?",
      [approval, approvalMessage, id],
    );
    return result.affectedRows > 0;
  }

  async deleteAsset(id, ownerID) {
    const [result] = await db.query(
      "DELETE FROM asset WHERE id = ? AND owner_id = ?",
      [id, ownerID],
    );
    return result.affectedRows > 0;
  }
}

module.exports = new AssetRepository();
