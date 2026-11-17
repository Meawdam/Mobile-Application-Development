"use strict";

const argon2 = require("@node-rs/argon2");
const db = require("./db_config");

const APPLY = process.argv.includes("--apply");
const DEMO_PASSWORD = process.env.MOCK_DEMO_PASSWORD || "DemoPassword123!";
const USER_COUNT = 50;
const ASSET_COUNT = 150;
const BORROW_COUNT = 120;
const DAY_MS = 24 * 60 * 60 * 1000;

function dateOffset(days) {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

function dateTimeOffset(days) {
  return new Date(Date.now() + days * DAY_MS);
}

function money(value) {
  return value.toFixed(2);
}

async function addActivity(connection, entry) {
  await connection.execute(
    `INSERT INTO user_activity_logs (
      user_id, actor_id, category, action, entity_type, entity_id,
      message, details, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      entry.userId,
      entry.actorId,
      entry.category,
      entry.action,
      entry.entityType,
      entry.entityId,
      entry.message,
      entry.details ? JSON.stringify(entry.details) : null,
      entry.createdAt,
    ],
  );
}

async function addTransaction(connection, transaction) {
  await connection.execute(
    `INSERT INTO financial_transactions (
      user_id, actor_id, borrow_id, transaction_type, amount, status,
      description, created_at, processed_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      transaction.userId,
      transaction.actorId,
      transaction.borrowId,
      transaction.type,
      money(transaction.amount),
      transaction.status,
      transaction.description,
      transaction.createdAt,
      transaction.processedAt,
    ],
  );
}

async function seed() {
  const connection = await db.getConnection();
  try {
    const [databaseRows] = await connection.query("SELECT DATABASE() AS name");
    if (databaseRows[0].name !== "borrow") {
      throw new Error("Refusing to seed a database other than borrow.");
    }

    const [existingAssets] = await connection.execute(
      "SELECT id FROM asset WHERE description LIKE ? LIMIT 1",
      ["[DEMO SEED] %"],
    );
    if (existingAssets.length > 0) {
      console.log("Admin mock data already exists; no changes made.");
      return;
    }

    const [existingAdmin] = await connection.execute(
      "SELECT id, role FROM users WHERE username = ?",
      ["demo_admin"],
    );
    if (existingAdmin.length > 0 && existingAdmin[0].role !== "admin") {
      throw new Error("The demo_admin username already exists without admin role.");
    }

    if (!APPLY) {
      console.log(
        JSON.stringify({
          target: "borrow",
          dryRun: true,
          willCreate: {
            adminAccounts: existingAdmin.length === 0 ? 1 : 0,
            userAccounts: USER_COUNT,
            assets: ASSET_COUNT,
            borrows: BORROW_COUNT,
            transactions: "about 225",
            activityLogs: "about 400",
          },
          applyCommand: "node seed_admin_mock_data.js --apply",
        }),
      );
      return;
    }

    await connection.beginTransaction();
    const passwordHash = await argon2.hash(DEMO_PASSWORD);
    let adminId;

    if (existingAdmin.length > 0) {
      adminId = existingAdmin[0].id;
    } else {
      const [result] = await connection.execute(
        `INSERT INTO users (
          username, email, password, phone_num, role, wallet_balance,
          is_suspended, created_at
        ) VALUES (?, ?, ?, ?, 'admin', 0, 0, ?)`,
        [
          "demo_admin",
          "demo_admin@mock.test",
          passwordHash,
          "0800000000",
          dateTimeOffset(-30),
        ],
      );
      adminId = result.insertId;
    }

    const users = [];
    for (let index = 1; index <= USER_COUNT; index += 1) {
      const suffix = String(index).padStart(3, "0");
      const isSuspended = index % 19 === 0;
      const [result] = await connection.execute(
        `INSERT INTO users (
          username, email, password, phone_num, role, wallet_balance,
          is_suspended, suspension_reason, suspended_at, created_at
        ) VALUES (?, ?, ?, ?, 'user', 0, ?, ?, ?, ?)`,
        [
          `demo_user_${suffix}`,
          `demo_user_${suffix}@mock.test`,
          passwordHash,
          `08${String(10000000 + index).slice(-8)}`,
          isSuspended ? 1 : 0,
          isSuspended ? "Demo suspension for admin testing" : null,
          isSuspended ? dateTimeOffset(-2) : null,
          dateTimeOffset(-USER_COUNT + index),
        ],
      );
      users.push(result.insertId);
    }

    const assetNames = [
      "Digital Multimeter",
      "Scientific Calculator",
      "DSLR Camera",
      "Tripod Stand",
      "Wireless Microphone",
      "Portable Projector",
      "Laboratory Microscope",
      "Soldering Station",
      "Drawing Tablet",
      "Portable Monitor",
      "Camping Tent",
      "Electric Drill",
      "Studio Light Kit",
      "VR Headset",
      "Document Scanner",
    ];
    const assets = [];
    for (let index = 0; index < ASSET_COUNT; index += 1) {
      const ownerId = users[(index * 7) % users.length];
      let approval = "approved";
      let status = "ready";
      let approvalMessage = null;
      if (index < 25) {
        approval = "pending";
      } else if (index < 40) {
        approval = "not approve";
        approvalMessage = "Demo rejection reason for admin testing";
      } else if (index >= 120) {
        status = "borrowed";
      }

      const suffix = String(index + 1).padStart(3, "0");
      const [result] = await connection.execute(
        `INSERT INTO asset (
          owner_id, name, description, status, approval, approval_message,
          down_payment, return_before, price, pickup_point, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          ownerId,
          `${assetNames[index % assetNames.length]} ${suffix}`,
          `[DEMO SEED] Mock inventory item ${suffix} for admin testing`,
          status,
          approval,
          approvalMessage,
          money(200 + (index % 10) * 100),
          dateOffset(180 + (index % 30)),
          money(40 + (index % 15) * 20),
          `Campus pickup point ${(index % 8) + 1}`,
          dateTimeOffset(-(index % 120)),
        ],
      );
      assets.push({ id: result.insertId, ownerId, status, approval });

      await addActivity(connection, {
        userId: ownerId,
        actorId: approval === "pending" ? ownerId : adminId,
        category: approval === "pending" ? "rental" : "admin",
        action:
          approval === "pending"
            ? "asset_submitted"
            : approval === "approved"
              ? "asset_approved"
              : "asset_rejected",
        entityType: "asset",
        entityId: result.insertId,
        message:
          approval === "pending"
            ? "Asset submitted for admin approval"
            : approval === "approved"
              ? "Asset approved by admin"
              : "Asset rejected by admin",
        details: { name: `${assetNames[index % assetNames.length]} ${suffix}` },
        createdAt: dateTimeOffset(-(index % 120)),
      });
    }

    const borrowStatuses = [
      { status: "returned_confirmed", paymentStatus: "paid", refund: "pending" },
      {
        status: "returned_confirmed",
        paymentStatus: "refunded",
        refund: "completed",
      },
      {
        status: "returned_confirmed",
        paymentStatus: "forfeited",
        refund: "forfeited",
      },
      { status: "returned_pending", paymentStatus: "paid" },
      { status: "rejected", paymentStatus: "unpaid" },
      { status: "cancelled", paymentStatus: "unpaid" },
      {
        status: "returned_confirmed",
        paymentStatus: "refunded",
        refund: "completed",
      },
      { status: "returned_confirmed", paymentStatus: "paid", refund: "pending" },
    ];

    const balances = new Map(users.map((userId) => [userId, 0]));
    const borrowRecords = [];
    for (let index = 0; index < BORROW_COUNT; index += 1) {
      const isCurrent = index < 30;
      const asset = isCurrent
        ? assets[120 + index]
        : assets[40 + ((index - 30) % 80)];
      const borrowerIndex = (index * 11 + 3) % users.length;
      const borrowerId =
        users[borrowerIndex] === asset.ownerId
          ? users[(borrowerIndex + 1) % users.length]
          : users[borrowerIndex];
      const state = isCurrent
        ? { status: "borrowed", paymentStatus: "paid" }
        : borrowStatuses[(index - 30) % borrowStatuses.length];
      const rentalDays = 1 + (index % 7);
      const rentalAmount = (40 + (index % 15) * 20) * rentalDays;
      const depositAmount = 200 + (index % 10) * 100;
      const totalAmount = rentalAmount + depositAmount;
      const daysAgo = isCurrent
        ? 2 + (index % 20)
        : 10 + ((index - 30) % 90);
      const pickupDate = dateOffset(-daysAgo);
      const plannedReturnDate = dateOffset(
        isCurrent ? 8 + (index % 5) : -daysAgo + rentalDays - 1,
      );
      const createdAt = dateTimeOffset(-daysAgo);
      const returnedAt = dateTimeOffset(
        -Math.max(1, daysAgo - rentalDays + 1),
      );
      const receivedAt = isCurrent
        ? dateTimeOffset(-Math.max(0, daysAgo - 1))
        : state.status === "returned_pending" ||
            state.status === "returned_confirmed"
          ? dateTimeOffset(-Math.max(1, daysAgo - 1))
          : null;
      const returnDate =
        isCurrent || state.status === "rejected" || state.status === "cancelled"
          ? null
          : returnedAt;

      const [result] = await connection.execute(
        `INSERT INTO borrow (
          asset_id, borrower_id, pickup_date, planned_return_date, rental_days,
          rental_amount, deposit_amount, total_amount, borrow_date, received_at,
          return_date, status, payment_status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          asset.id,
          borrowerId,
          pickupDate,
          plannedReturnDate,
          rentalDays,
          money(rentalAmount),
          money(depositAmount),
          money(totalAmount),
          createdAt,
          receivedAt,
          returnDate,
          state.status,
          state.paymentStatus,
          createdAt,
        ],
      );
      const borrowId = result.insertId;
      borrowRecords.push(borrowId);

      if (
        ["paid", "refunded", "forfeited"].includes(state.paymentStatus)
      ) {
        await addTransaction(connection, {
          userId: borrowerId,
          actorId: borrowerId,
          borrowId,
          type: "rental_payment",
          amount: rentalAmount,
          status: "completed",
          description: "Rental payment (demo seed)",
          createdAt,
          processedAt: createdAt,
        });

        const depositStatus =
          state.paymentStatus === "paid" ? "pending" : "released";
        await addTransaction(connection, {
          userId: borrowerId,
          actorId: borrowerId,
          borrowId,
          type: "deposit_hold",
          amount: depositAmount,
          status: depositStatus,
          description: "Deposit held (demo seed)",
          createdAt,
          processedAt: depositStatus === "released" ? returnedAt : null,
        });

        if (state.refund === "pending" || state.refund === "completed") {
          await addTransaction(connection, {
            userId: borrowerId,
            actorId: state.refund === "completed" ? adminId : null,
            borrowId,
            type: "deposit_refund",
            amount: depositAmount,
            status: state.refund,
            description:
              state.refund === "pending"
                ? "Deposit refund awaiting admin processing (demo seed)"
                : "Deposit refund completed (demo seed)",
            createdAt: returnedAt,
            processedAt:
              state.refund === "completed" ? returnedAt : null,
          });
        }
        if (state.paymentStatus === "forfeited") {
          await addTransaction(connection, {
            userId: asset.ownerId,
            actorId: null,
            borrowId,
            type: "deposit_forfeiture",
            amount: depositAmount,
            status: "completed",
            description: "Deposit forfeited (demo seed)",
            createdAt: returnedAt,
            processedAt: returnedAt,
          });
        }
      }

      const activity = {
        userId: borrowerId,
        actorId: borrowerId,
        category: "rental",
        action: `borrow_${state.status}`,
        entityType: "borrow",
        entityId: borrowId,
        message: `Demo borrow record: ${state.status.replaceAll("_", " ")}`,
        details: { asset_id: asset.id, rental_amount: rentalAmount },
        createdAt,
      };
      await addActivity(connection, activity);
      await addActivity(connection, { ...activity, userId: asset.ownerId });
    }

    for (let index = 0; index < 35; index += 1) {
      const userId = users[(index * 3) % users.length];
      const amount = 500 + (index % 8) * 250;
      balances.set(userId, balances.get(userId) + amount);
      const createdAt = dateTimeOffset(-(index * 2));
      await addTransaction(connection, {
        userId,
        actorId: userId,
        borrowId: null,
        type: "wallet_top_up",
        amount,
        status: "completed",
        description: "Wallet top-up (demo seed)",
        createdAt,
        processedAt: createdAt,
      });
      await addActivity(connection, {
        userId,
        actorId: userId,
        category: "finance",
        action: "wallet_top_up",
        entityType: "wallet",
        entityId: null,
        message: "Wallet topped up (demo seed)",
        details: { amount },
        createdAt,
      });
    }

    for (const [userId, balance] of balances) {
      await connection.execute(
        "UPDATE users SET wallet_balance = ? WHERE id = ?",
        [money(balance), userId],
      );
    }

    await connection.commit();
    console.log(
      JSON.stringify({
        database: "borrow",
        created: {
          adminAccounts: existingAdmin.length === 0 ? 1 : 0,
          userAccounts: USER_COUNT,
          assets: assets.length,
          borrows: borrowRecords.length,
          walletTopUps: 35,
          activityLogs: "asset submissions/reviews, borrow history, and top-ups",
        },
        adminLogin: {
          email: "demo_admin@mock.test",
          password: DEMO_PASSWORD,
        },
      }),
    );
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

seed()
  .catch((error) => {
    console.error(`Mock data seeding failed: ${error.message}`);
    process.exitCode = 1;
  })
  .finally(() => db.end());
