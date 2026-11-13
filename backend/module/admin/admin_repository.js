const db = require("../../db_config");
const { logActivities } = require("../../utils/activity_logger");

class AdminRepository {
  async getDashboard() {
    const [assets] = await db.query(
      `SELECT
        COUNT(*) AS total,
        COALESCE(SUM(approval = 'approved'), 0) AS approved,
        COALESCE(SUM(approval = 'pending'), 0) AS pending,
        COALESCE(SUM(status = 'borrowed'), 0) AS borrowed
       FROM asset`,
    );
    const [borrowingVolume] = await db.query(
      `SELECT DATE_FORMAT(created_at, '%Y-%m-%d') AS date,
        COUNT(*) AS count
       FROM borrow
       WHERE created_at >= CURRENT_DATE() - INTERVAL 6 DAY
       GROUP BY DATE(created_at)
       ORDER BY DATE(created_at)`,
    );
    const [finance] = await db.query(
      `SELECT
        COALESCE(SUM(CASE
          WHEN transaction_type = 'rental_payment' AND status = 'completed'
          THEN amount ELSE 0 END), 0) AS collected_revenue,
        COALESCE(SUM(CASE
          WHEN transaction_type = 'deposit_hold' AND status = 'pending'
          THEN amount ELSE 0 END), 0) AS held_deposits,
        COALESCE(SUM(CASE
          WHEN transaction_type = 'deposit_refund' AND status = 'completed'
          THEN amount ELSE 0 END), 0) AS processed_refunds,
        COALESCE(SUM(CASE
          WHEN transaction_type = 'deposit_refund' AND status = 'pending'
          THEN 1 ELSE 0 END), 0) AS pending_refunds,
        COALESCE(SUM(CASE
          WHEN transaction_type = 'deposit_forfeiture' AND status = 'completed'
          THEN amount ELSE 0 END), 0) AS forfeited_deposits
       FROM financial_transactions`,
    );

    return {
      assets: {
        total: Number(assets[0].total),
        approved: Number(assets[0].approved),
        pending: Number(assets[0].pending),
        borrowed: Number(assets[0].borrowed),
      },
      borrowing_volume_last_7_days: borrowingVolume.map((row) => ({
        date: row.date,
        count: Number(row.count),
      })),
      finance: {
        collected_revenue: Number(finance[0].collected_revenue),
        held_deposits: Number(finance[0].held_deposits),
        processed_refunds: Number(finance[0].processed_refunds),
        pending_refunds: Number(finance[0].pending_refunds),
        forfeited_deposits: Number(finance[0].forfeited_deposits),
      },
    };
  }

  async findTransactions({ type, status, search, limit, offset }) {
    const conditions = [];
    const params = [];
    if (type) {
      conditions.push("ft.transaction_type = ?");
      params.push(type);
    }
    if (status) {
      conditions.push("ft.status = ?");
      params.push(status);
    }
    if (search) {
      conditions.push(
        `(u.username LIKE ? OR a.name LIKE ? OR
          ft.description LIKE ? OR CAST(ft.borrow_id AS CHAR) LIKE ?)`,
      );
      const query = `%${search}%`;
      params.push(query, query, query, query);
    }
    const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
    const [rows] = await db.query(
      `SELECT ft.id, ft.user_id,
        u.username AS user_name, ft.actor_id,
        actor.username AS actor_name, ft.borrow_id,
        a.name AS asset_name, ft.transaction_type,
        ft.amount, ft.status, ft.description,
        ft.created_at, ft.processed_at
       FROM financial_transactions ft
       JOIN users u ON u.id = ft.user_id
       LEFT JOIN users actor ON actor.id = ft.actor_id
       LEFT JOIN borrow b ON b.id = ft.borrow_id
       LEFT JOIN asset a ON a.id = b.asset_id
       ${where}
       ORDER BY ft.created_at DESC, ft.id DESC
       LIMIT ? OFFSET ?`,
      [...params, limit, offset],
    );
    const [counts] = await db.query(
      `SELECT COUNT(*) AS total
       FROM financial_transactions ft
       JOIN users u ON u.id = ft.user_id
       LEFT JOIN borrow b ON b.id = ft.borrow_id
       LEFT JOIN asset a ON a.id = b.asset_id
       ${where}`,
      params,
    );
    return { rows, total: Number(counts[0].total) };
  }

  async processRefund(transactionId, adminId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [transactions] = await connection.query(
        `SELECT ft.id, ft.user_id, ft.borrow_id, ft.amount, ft.status,
          b.status AS borrow_status, b.payment_status, a.owner_id
         FROM financial_transactions ft
         JOIN borrow b ON b.id = ft.borrow_id
         JOIN asset a ON a.id = b.asset_id
         WHERE ft.id = ?
           AND ft.transaction_type = 'deposit_refund'
         FOR UPDATE`,
        [transactionId],
      );
      if (transactions.length === 0) {
        await connection.rollback();
        return null;
      }

      const transaction = transactions[0];
      if (
        transaction.status !== "pending" ||
        transaction.borrow_status !== "returned_confirmed" ||
        transaction.payment_status !== "paid"
      ) {
        await connection.rollback();
        return false;
      }

      const [users] = await connection.query(
        "SELECT wallet_balance FROM users WHERE id = ? FOR UPDATE",
        [transaction.user_id],
      );
      if (users.length === 0) {
        const err = new Error("Refund recipient no longer exists");
        err.status = 409;
        throw err;
      }
      const amount = Number(transaction.amount);
      await connection.query(
        "UPDATE users SET wallet_balance = wallet_balance + ? WHERE id = ?",
        [amount, transaction.user_id],
      );
      const [updated] = await connection.query(
        `UPDATE financial_transactions
         SET status = 'completed', actor_id = ?, processed_at = NOW()
         WHERE id = ? AND status = 'pending'`,
        [adminId, transactionId],
      );
      if (updated.affectedRows === 0) {
        await connection.rollback();
        return false;
      }
      const [borrowUpdate] = await connection.query(
        `UPDATE borrow SET payment_status = 'refunded'
         WHERE id = ? AND status = 'returned_confirmed'
           AND payment_status = 'paid'`,
        [transaction.borrow_id],
      );
      if (borrowUpdate.affectedRows === 0) {
        const err = new Error("Borrow record is no longer eligible for refund");
        err.status = 409;
        throw err;
      }
      await connection.query(
        `UPDATE financial_transactions
         SET status = 'released', processed_at = NOW()
         WHERE borrow_id = ? AND transaction_type = 'deposit_hold'
           AND status = 'pending'`,
        [transaction.borrow_id],
      );

      await logActivities(
        [
          {
            userId: Number(transaction.user_id),
            actorId: adminId,
            category: "finance",
            action: "deposit_refunded",
            entityType: "borrow",
            entityId: Number(transaction.borrow_id),
            message: "Deposit refund processed",
            details: { amount, transaction_id: Number(transactionId) },
          },
          {
            userId: Number(transaction.owner_id),
            actorId: adminId,
            category: "finance",
            action: "deposit_refunded",
            entityType: "borrow",
            entityId: Number(transaction.borrow_id),
            message: "Borrower deposit refund processed",
            details: { amount, transaction_id: Number(transactionId) },
          },
        ],
        connection,
      );
      const walletBalance = Number(users[0].wallet_balance) + amount;
      await connection.commit();
      return {
        id: Number(transactionId),
        borrow_id: Number(transaction.borrow_id),
        user_id: Number(transaction.user_id),
        amount,
        status: "completed",
        wallet_balance: walletBalance,
      };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }
}

module.exports = new AdminRepository();
