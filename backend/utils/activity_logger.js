const db = require("../db_config");

async function logActivities(entries, executor = db) {
  for (const entry of entries) {
    await executor.query(
      `INSERT INTO user_activity_logs (
        user_id, actor_id, category, action, entity_type, entity_id,
        message, details
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        entry.userId,
        entry.actorId ?? null,
        entry.category,
        entry.action,
        entry.entityType ?? null,
        entry.entityId ?? null,
        entry.message,
        entry.details ? JSON.stringify(entry.details) : null,
      ],
    );
  }
}

function borrowActivityEntries({
  borrowerId,
  ownerId,
  actorId,
  action,
  message,
  borrowId,
  details,
}) {
  const users = new Set([borrowerId, ownerId]);
  return [...users].map((userId) => ({
    userId,
    actorId,
    category: "rental",
    action,
    entityType: "borrow",
    entityId: borrowId,
    message,
    details,
  }));
}

module.exports = { logActivities, borrowActivityEntries };
