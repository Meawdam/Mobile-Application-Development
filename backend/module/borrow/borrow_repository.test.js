const assert = require("node:assert/strict");
const { test } = require("node:test");
const db = require("../../db_config");
const borrowRepository = require("./borrow_repository");

function createConnection(queryHandler) {
  const statements = [];
  return {
    statements,
    async beginTransaction() {},
    async commit() {},
    async rollback() {},
    release() {},
    async query(sql, params) {
      statements.push({ sql, params });
      return queryHandler(sql, params);
    },
  };
}

function mutationResult(affectedRows = 1) {
  return [{ affectedRows }, []];
}

test("overdue deposit is credited to owner and is not refunded on return confirmation", async () => {
  const originalGetConnection = db.getConnection;
  const connection = createConnection(async (sql) => {
    if (sql.includes("FROM borrow b") && sql.includes("LIMIT ?")) {
      return [[{
        id: 21,
        borrower_id: 7,
        deposit_amount: 250,
        status: "returned_pending",
        payment_status: "paid",
        owner_id: 9,
      }], []];
    }
    if (sql.includes("SELECT id, amount FROM financial_transactions")) {
      return [[{ id: 45, amount: 250 }], []];
    }
    if (sql.includes("SELECT id FROM users")) {
      return [[{ id: 9 }], []];
    }
    return mutationResult();
  });

  db.getConnection = async () => connection;
  try {
    const forfeited = await borrowRepository.forfeitOverdueDeposits();

    assert.equal(forfeited, 1);
    assert.ok(
      connection.statements.some(({ sql }) =>
        sql.includes("b.planned_return_date < CURRENT_DATE()"),
      ),
    );
    assert.ok(
      connection.statements.some(({ sql, params }) =>
        sql.includes("UPDATE users SET wallet_balance = wallet_balance +") &&
        params[1] === 9 &&
        params[0] === 250,
      ),
    );
    assert.ok(
      connection.statements.some(({ sql, params }) =>
        sql.includes("'deposit_forfeiture'") &&
        params[0] === 9 &&
        params[2] === 250,
      ),
    );

    const confirmConnection = createConnection(async (sql) => {
      if (sql.startsWith("SELECT b.id") && sql.includes("a.status AS asset_status")) {
        return [[{
          id: 21,
          borrower_id: 7,
          deposit_amount: 250,
          status: "returned_pending",
          payment_status: "paid",
          planned_return_date: "2026-11-12",
          return_deadline_passed: 1,
          owner_id: 9,
          asset_status: "borrowed",
        }], []];
      }
      if (sql.includes("SELECT id, amount FROM financial_transactions")) {
        return [[{ id: 45, amount: 250 }], []];
      }
      if (sql.includes("SELECT id FROM users")) {
        return [[{ id: 9 }], []];
      }
      return mutationResult();
    });
    db.getConnection = async () => confirmConnection;

    const confirmed = await borrowRepository.confirmReturn(21, 33, 7, 9);

    assert.equal(confirmed.deposit_forfeited, 250);
    assert.equal(confirmed.refund_pending, 0);
    assert.ok(
      confirmConnection.statements.some(({ sql, params }) =>
        sql.includes("SET payment_status = 'forfeited'") && params[0] === 21,
      ),
    );
    assert.ok(
      !confirmConnection.statements.some(({ sql }) =>
        sql.includes("'deposit_refund'"),
      ),
    );
  } finally {
    db.getConnection = originalGetConnection;
  }
});
