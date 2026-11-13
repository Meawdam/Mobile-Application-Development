const db = require("../../db_config");
const { logActivities } = require("../../utils/activity_logger");

class userRepository {
    async findAll() {
        const [rows] = await db.query(
            `SELECT u.id, u.username, u.email, u.phone_num, u.role,
              u.is_suspended, u.suspension_reason, u.suspended_at,
              (SELECT COUNT(*) FROM borrow b
               LEFT JOIN asset a ON a.id = b.asset_id
               WHERE b.borrower_id = u.id OR a.owner_id = u.id) AS total_records,
              (SELECT COUNT(*) FROM borrow b
               JOIN asset a ON a.id = b.asset_id
               WHERE a.owner_id = u.id) AS lending,
              (SELECT COUNT(*) FROM borrow b
               JOIN asset a ON a.id = b.asset_id
               WHERE (b.borrower_id = u.id OR a.owner_id = u.id)
                 AND b.status IN ('borrowed', 'returned_pending')
                 AND b.planned_return_date < CURRENT_DATE()) AS overdue
             FROM users u
             ORDER BY u.id`
        );
        return rows;
    }

    async findById(id) {
        const [rows] = await db.query(
            `SELECT u.id, u.username, u.email, u.phone_num, u.role,
              u.is_suspended, u.suspension_reason, u.suspended_at,
              (SELECT COUNT(*) FROM borrow b
               LEFT JOIN asset a ON a.id = b.asset_id
               WHERE b.borrower_id = u.id OR a.owner_id = u.id) AS total_records,
              (SELECT COUNT(*) FROM borrow b
               JOIN asset a ON a.id = b.asset_id
               WHERE a.owner_id = u.id) AS lending,
              (SELECT COUNT(*) FROM borrow b
               JOIN asset a ON a.id = b.asset_id
               WHERE (b.borrower_id = u.id OR a.owner_id = u.id)
                 AND b.status IN ('borrowed', 'returned_pending')
                 AND b.planned_return_date < CURRENT_DATE()) AS overdue
             FROM users u WHERE u.id = ?`,
            [id]
        );
        return rows[0];
    }

    async setSuspension(id, actorId, isSuspended, reason) {
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();
            const [users] = await connection.query(
                "SELECT id FROM users WHERE id = ? FOR UPDATE",
                [id],
            );
            if (users.length === 0) {
                await connection.rollback();
                return null;
            }

            await connection.query(
                `UPDATE users
                 SET is_suspended = ?, suspension_reason = ?,
                     suspended_at = ?
                 WHERE id = ?`,
                [
                    isSuspended ? 1 : 0,
                    isSuspended ? reason : null,
                    isSuspended ? new Date() : null,
                    id,
                ],
            );
            await logActivities(
                [{
                    userId: Number(id),
                    actorId,
                    category: "admin",
                    action: isSuspended ? "account_suspended" : "account_activated",
                    entityType: "user",
                    entityId: Number(id),
                    message: isSuspended
                        ? "Account suspended"
                        : "Account reactivated",
                    details: isSuspended ? { reason } : undefined,
                }],
                connection,
            );
            await connection.commit();
            return {
                id: Number(id),
                is_suspended: isSuspended,
                suspension_reason: isSuspended ? reason : null,
            };
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    async findActivities(userId, category, limit, offset) {
        const filters = ["activity.user_id = ?"];
        const params = [userId];
        if (category) {
            filters.push("activity.category = ?");
            params.push(category);
        }
        params.push(limit, offset);

        const [rows] = await db.query(
            `SELECT activity.id, activity.category, activity.action,
              activity.entity_type, activity.entity_id, activity.message,
              activity.details, activity.created_at,
              actor.username AS actor_username
             FROM user_activity_logs activity
             LEFT JOIN users actor ON actor.id = activity.actor_id
             WHERE ${filters.join(" AND ")}
             ORDER BY activity.created_at DESC, activity.id DESC
             LIMIT ? OFFSET ?`,
            params,
        );
        return rows;
    }
}

module.exports = new userRepository();