const db = require("../../db_config");
const { logActivities } = require("../../utils/activity_logger");

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

  async findByIdForViewer(id, viewerId, viewerRole) {
    const [rows] = await db.query(
      `SELECT a.*, u.username AS owner_username
       FROM asset a
       LEFT JOIN users u ON u.id = a.owner_id
       WHERE a.id = ?
         AND (a.approval = 'approved' OR a.owner_id = ? OR ? = 'admin')`,
      [id, viewerId ?? null, viewerRole ?? null],
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
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [result] = await connection.query(
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
      await logActivities(
        [{
          userId: owner_id,
          actorId: owner_id,
          category: "rental",
          action: "asset_submitted",
          entityType: "asset",
          entityId: result.insertId,
          message: "Asset submitted for admin approval",
          details: { name },
        }],
        connection,
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

  async updateAsset(id, ownerId, data) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [result] = await connection.query(
        `UPDATE asset
         SET name = ?, description = ?, down_payment = ?, price = ?,
             pickup_point = ?, return_before = ?
         WHERE id = ? AND owner_id = ? AND status <> 'borrowed'`,
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
      if (result.affectedRows > 0) {
        await logActivities(
          [{
            userId: ownerId,
            actorId: ownerId,
            category: "rental",
            action: "asset_updated",
            entityType: "asset",
            entityId: Number(id),
            message: "Asset details updated",
            details: { name: data.name },
          }],
          connection,
        );
      }
      await connection.commit();
      return result.affectedRows > 0;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async updateApproval(id, ownerId, adminId, approval, approvalMessage) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [result] = await connection.query(
        "UPDATE asset SET approval = ?, approval_message = ? WHERE id = ?",
        [approval, approvalMessage, id],
      );
      if (result.affectedRows > 0) {
        await logActivities(
          [{
            userId: ownerId,
            actorId: adminId,
            category: "admin",
            action: approval === "approved" ? "asset_approved" : "asset_rejected",
            entityType: "asset",
            entityId: Number(id),
            message: approval === "approved"
              ? "Asset approved by admin"
              : "Asset rejected by admin",
            details: approvalMessage ? { reason: approvalMessage } : undefined,
          }],
          connection,
        );
      }
      await connection.commit();
      return result.affectedRows > 0;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async deleteAsset(id, ownerID) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [assets] = await connection.query(
        "SELECT id, status FROM asset WHERE id = ? AND owner_id = ? FOR UPDATE",
        [id, ownerID],
      );
      if (assets.length === 0) {
        await connection.rollback();
        return false;
      }
      if (assets[0].status === "borrowed") {
        const err = new Error("Cannot delete an asset while it is borrowed");
        err.status = 409;
        throw err;
      }
      const [borrowHistory] = await connection.query(
        "SELECT id FROM borrow WHERE asset_id = ? LIMIT 1",
        [id],
      );
      if (borrowHistory.length > 0) {
        const err = new Error("Cannot delete an asset with borrow history");
        err.status = 409;
        throw err;
      }
      const [result] = await connection.query(
        "DELETE FROM asset WHERE id = ? AND owner_id = ?",
        [id, ownerID],
      );
      if (result.affectedRows > 0) {
        await logActivities(
          [{
            userId: ownerID,
            actorId: ownerID,
            category: "rental",
            action: "asset_deleted",
            entityType: "asset",
            entityId: Number(id),
            message: "Asset deleted",
          }],
          connection,
        );
      }
      await connection.commit();
      return result.affectedRows > 0;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }
}

module.exports = new AssetRepository();
