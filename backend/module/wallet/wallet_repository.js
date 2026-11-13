const db = require("../../db_config");
const { logActivities } = require("../../utils/activity_logger");
const {
  MAX_STORED_AMOUNT_CENTS,
  amountCentsToNumber,
  formatAmountCents,
  parseAmountCents,
} = require("../../utils/money_utils");

class WalletRepository {
  async getBalance(userId) {
    const [rows] = await db.query(
      "SELECT wallet_balance FROM users WHERE id = ?",
      [userId],
    );
    return rows[0] ? Number(rows[0].wallet_balance) : null;
  }

  async topUp(userId, amount) {
    const amountCents = parseAmountCents(amount);
    if (amountCents === null || amountCents <= 0) {
      throw new Error("Invalid top-up amount");
    }
    const formattedAmount = formatAmountCents(amountCents);
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
      const currentBalanceCents = parseAmountCents(users[0].wallet_balance);
      if (
        currentBalanceCents === null ||
        currentBalanceCents + amountCents > MAX_STORED_AMOUNT_CENTS
      ) {
        const err = new Error("Wallet balance exceeds the supported range");
        err.status = 409;
        throw err;
      }

      await connection.query(
        "UPDATE users SET wallet_balance = wallet_balance + ? WHERE id = ?",
        [formattedAmount, userId],
      );
      await connection.query(
        `INSERT INTO financial_transactions
          (user_id, actor_id, transaction_type, amount, status, description)
         VALUES (?, ?, 'wallet_top_up', ?, 'completed', 'Wallet top-up')`,
        [userId, userId, formattedAmount],
      );
      await logActivities(
        [{
          userId,
          actorId: userId,
          category: "finance",
          action: "wallet_topped_up",
          entityType: "wallet",
          message: "Wallet topped up",
          details: { amount: amountCentsToNumber(amountCents) },
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
