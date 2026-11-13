const db = require("../../db_config");
const { logActivities } = require("../../utils/activity_logger");

class WalletRepository {
  async getBalance(userId) {
    const [rows] = await db.query(
      "SELECT wallet_balance FROM users WHERE id = ?",
      [userId],
    );
    return rows[0] ? Number(rows[0].wallet_balance) : null;
  }

  async topUp(userId, amount) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [users] = await connection.query(
        "SELECT wallet_balance FROM users WHERE id = ? FOR UPDATE",
        [userId],
      );
      if (users.length === 0) {
        const err = new Error("User not found");
        err.status = 404;
        throw err;
      }

      await connection.query(
        "UPDATE users SET wallet_balance = wallet_balance + ? WHERE id = ?",
        [amount, userId],
      );
      await connection.query(
        `INSERT INTO financial_transactions
          (user_id, actor_id, transaction_type, amount, status, description)
         VALUES (?, ?, 'wallet_top_up', ?, 'completed', 'Wallet top-up')`,
        [userId, userId, amount],
      );
      await logActivities(
        [{
          userId,
          actorId: userId,
          category: "finance",
          action: "wallet_topped_up",
          entityType: "wallet",
          message: "Wallet topped up",
          details: { amount },
        }],
        connection,
      );
      const [updated] = await connection.query(
        "SELECT wallet_balance FROM users WHERE id = ?",
        [userId],
      );
      await connection.commit();
      return Number(updated[0].wallet_balance);
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }
}

module.exports = new WalletRepository();
