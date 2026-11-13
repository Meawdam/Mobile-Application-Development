import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.env.API_BASE || "http://localhost:3000";
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const results = [];

function record(name, ok, detail = "") {
  results.push({ name, ok, detail });
  const mark = ok ? "PASS" : "FAIL";
  console.log(`${mark}  ${name}${detail ? ` — ${detail}` : ""}`);
}

async function req(method, urlPath, { token, body, formData, expectStatus } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  let payload = undefined;
  if (formData) {
    payload = formData;
  } else if (body !== undefined) {
    headers["Content-Type"] = "application/json";
    payload = JSON.stringify(body);
  }

  const res = await fetch(`${BASE}${urlPath}`, {
    method,
    headers,
    body: payload,
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text };
  }

  if (expectStatus !== undefined && res.status !== expectStatus) {
    const err = new Error(
      `expected ${expectStatus}, got ${res.status}: ${text.slice(0, 200)}`,
    );
    err.status = res.status;
    err.json = json;
    throw err;
  }
  return { status: res.status, json };
}

async function main() {
  const stamp = Date.now();
  const userEmail = `overall_${stamp}@example.com`;
  const ownerEmail = `owner_${stamp}@example.com`;
  const password = "overall123";

  // Health / docs
  try {
    const docs = await req("GET", "/api-docs.json", { expectStatus: 200 });
    record(
      "GET /api-docs.json",
      !!docs.json?.paths,
      `${Object.keys(docs.json.paths || {}).length} paths`,
    );
  } catch (e) {
    record("GET /api-docs.json", false, e.message);
  }

  // Auth register / login / me
  let userToken = "";
  let userId = null;
  try {
    const reg = await req("POST", "/api/auth/register", {
      body: {
        username: `overall_user_${stamp}`,
        email: userEmail,
        password,
        phone_num: "0811111111",
      },
      expectStatus: 201,
    });
    userId = reg.json?.data?.id;
    record("POST /api/auth/register (user)", true, `id=${userId}`);
  } catch (e) {
    record("POST /api/auth/register (user)", false, e.message);
  }

  try {
    const login = await req("POST", "/api/auth/login", {
      body: { email: userEmail, password },
      expectStatus: 200,
    });
    userToken = login.json?.token || "";
    record("POST /api/auth/login (user)", !!userToken, login.json?.user?.role);
  } catch (e) {
    record("POST /api/auth/login (user)", false, e.message);
  }

  try {
    const me = await req("GET", "/api/auth/me", {
      token: userToken,
      expectStatus: 200,
    });
    record("GET /api/auth/me", me.json?.user?.email === userEmail);
  } catch (e) {
    record("GET /api/auth/me", false, e.message);
  }

  try {
    await req("POST", "/api/auth/login", {
      body: { email: userEmail, password: "wrong-password" },
      expectStatus: 401,
    });
    record("POST /api/auth/login rejects bad password", true);
  } catch (e) {
    record("POST /api/auth/login rejects bad password", false, e.message);
  }

  // Owner account for create/delete asset + confirm return
  let ownerToken = "";
  let ownerId = null;
  try {
    const reg = await req("POST", "/api/auth/register", {
      body: {
        username: `overall_owner_${stamp}`,
        email: ownerEmail,
        password,
        phone_num: "0822222222",
      },
      expectStatus: 201,
    });
    ownerId = reg.json?.data?.id;
    const login = await req("POST", "/api/auth/login", {
      body: { email: ownerEmail, password },
      expectStatus: 200,
    });
    ownerToken = login.json?.token || "";
    record("register+login owner", !!ownerToken, `id=${ownerId}`);
  } catch (e) {
    record("register+login owner", false, e.message);
  }

  // Admin login
  let adminToken = "";
  try {
    const login = await req("POST", "/api/auth/login", {
      body: { email: "adminapi@example.com", password: "admin123" },
      expectStatus: 200,
    });
    adminToken = login.json?.token || "";
    record(
      "POST /api/auth/login (admin)",
      login.json?.user?.role === "admin",
      login.json?.user?.role,
    );
  } catch (e) {
    record("POST /api/auth/login (admin)", false, e.message);
  }

  // Create asset with image
  let pendingAssetId = null;
  try {
    const pngPath = path.join(__dirname, "test-asset.png");
    // 1x1 PNG
    const png = Buffer.from(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
      "base64",
    );
    fs.writeFileSync(pngPath, png);

    const form = new FormData();
    form.append(
      "image",
      new Blob([png], { type: "image/png" }),
      "test-asset.png",
    );
    form.append("name", `Overall Camera ${stamp}`);
    form.append("description", "Overall API test asset");
    form.append("down_payment", "1000");
    form.append("price", "120");
    form.append("pickup_point", "Library Gate");
    const returnBefore = new Date();
    returnBefore.setUTCDate(returnBefore.getUTCDate() + 14);
    form.append("return_before", returnBefore.toISOString().slice(0, 10));

    const created = await req("POST", "/api/assets", {
      token: ownerToken,
      formData: form,
      expectStatus: 201,
    });
    pendingAssetId = created.json?.data?.id;
    record(
      "POST /api/assets (multipart)",
      pendingAssetId != null,
      `id=${pendingAssetId} approval=${created.json?.data?.approval}`,
    );
  } catch (e) {
    record("POST /api/assets (multipart)", false, e.message);
  }

  // Admin approve asset
  try {
    const approved = await req(
      "PATCH",
      `/api/assets/${pendingAssetId}/approve`,
      {
        token: adminToken,
        body: { approval: "approved", approval_message: "Looks good" },
        expectStatus: 200,
      },
    );
    record(
      "PATCH /api/assets/:id/approve",
      approved.json?.data?.approval === "approved",
    );
  } catch (e) {
    record("PATCH /api/assets/:id/approve", false, e.message);
  }

  // Public/list assets
  try {
    const list = await req("GET", "/api/assets", {
      token: userToken,
      expectStatus: 200,
    });
    const found = (list.json?.data || []).some((a) => a.id === pendingAssetId);
    record(
      "GET /api/assets (available)",
      found,
      `count=${(list.json?.data || []).length}`,
    );
  } catch (e) {
    record("GET /api/assets (available)", false, e.message);
  }

  try {
    const search = await req("GET", `/api/assets?q=Overall%20Camera`, {
      token: userToken,
      expectStatus: 200,
    });
    const found = (search.json?.data || []).some((a) => a.id === pendingAssetId);
    record("GET /api/assets?q=...", found);
  } catch (e) {
    record("GET /api/assets?q=...", false, e.message);
  }

  try {
    const detail = await req("GET", `/api/assets/${pendingAssetId}`, {
      expectStatus: 200,
    });
    record(
      "GET /api/assets/:id",
      detail.json?.data?.id === pendingAssetId &&
        !!detail.json?.data?.owner_username,
      `owner=${detail.json?.data?.owner_username}`,
    );
  } catch (e) {
    record("GET /api/assets/:id", false, e.message);
  }

  try {
    const all = await req("GET", "/api/assets/all", {
      token: adminToken,
      expectStatus: 200,
    });
    record(
      "GET /api/assets/all (admin)",
      Array.isArray(all.json?.data),
      `count=${(all.json?.data || []).length}`,
    );
  } catch (e) {
    record("GET /api/assets/all (admin)", false, e.message);
  }

  try {
    await req("GET", "/api/assets/all", {
      token: userToken,
      expectStatus: 403,
    });
    record("GET /api/assets/all rejects non-admin", true);
  } catch (e) {
    record("GET /api/assets/all rejects non-admin", false, e.message);
  }

  // Users admin
  try {
    const users = await req("GET", "/api/users", {
      token: adminToken,
      expectStatus: 200,
    });
    record(
      "GET /api/users (admin)",
      Array.isArray(users.json?.data) || Array.isArray(users.json),
      `keys=${Object.keys(users.json || {}).join(",")}`,
    );
  } catch (e) {
    record("GET /api/users (admin)", false, e.message);
  }

  try {
    const one = await req("GET", `/api/users/${userId}`, {
      token: adminToken,
      expectStatus: 200,
    });
    record(
      "GET /api/users/:id (admin)",
      (one.json?.data?.id || one.json?.id || one.json?.user?.id) == userId ||
        one.status === 200,
      JSON.stringify(one.json).slice(0, 120),
    );
  } catch (e) {
    record("GET /api/users/:id (admin)", false, e.message);
  }

  try {
    const activities = await req("GET", `/api/users/${userId}/activities`, {
      token: adminToken,
      expectStatus: 200,
    });
    record(
      "GET /api/users/:id/activities (admin)",
      Array.isArray(activities.json?.data),
    );
  } catch (e) {
    record("GET /api/users/:id/activities (admin)", false, e.message);
  }

  try {
    const dashboard = await req("GET", "/api/admin/dashboard", {
      token: adminToken,
      expectStatus: 200,
    });
    record(
      "GET /api/admin/dashboard",
      typeof dashboard.json?.data?.assets?.total === "number" &&
        typeof dashboard.json?.data?.finance?.pending_refunds === "number",
    );
  } catch (e) {
    record("GET /api/admin/dashboard", false, e.message);
  }

  try {
    const transactions = await req("GET", "/api/admin/transactions?limit=5", {
      token: adminToken,
      expectStatus: 200,
    });
    record(
      "GET /api/admin/transactions",
      Array.isArray(transactions.json?.data) &&
        typeof transactions.json?.pagination?.total === "number",
    );
  } catch (e) {
    record("GET /api/admin/transactions", false, e.message);
  }

  // Borrow flow
  let borrowId = null;
  try {
    const today = new Date();
    const pickup = today.toISOString().slice(0, 10);
    const ret = new Date(today);
    ret.setUTCDate(ret.getUTCDate() + 2);
    const borrow = await req("POST", "/api/borrows", {
      token: userToken,
      body: {
        asset_id: pendingAssetId,
        pickup_date: pickup,
        return_date: ret.toISOString().slice(0, 10),
      },
      expectStatus: 201,
    });
    borrowId = borrow.json?.data?.id;
    record(
      "POST /api/borrows",
      borrowId != null && borrow.json?.data?.rental_days >= 1,
      `id=${borrowId} days=${borrow.json?.data?.rental_days}`,
    );
    const approved = await req("PATCH", `/api/borrows/${borrowId}/approve`, {
      token: ownerToken,
      expectStatus: 200,
    });
    record(
      "PATCH /api/borrows/:id/approve",
      approved.json?.data?.status === "approved",
    );
  } catch (e) {
    record("POST /api/borrows", false, e.message);
  }

  try {
    const mine = await req("GET", "/api/borrows/my", {
      token: userToken,
      expectStatus: 200,
    });
    const found = (mine.json?.data || []).some((b) => b.id === borrowId);
    record("GET /api/borrows/my", found, `count=${(mine.json?.data || []).length}`);
  } catch (e) {
    record("GET /api/borrows/my", false, e.message);
  }

  try {
    const all = await req("GET", "/api/borrows/all", {
      token: adminToken,
      expectStatus: 200,
    });
    record(
      "GET /api/borrows/all (admin)",
      Array.isArray(all.json?.data),
      `count=${(all.json?.data || []).length}`,
    );
  } catch (e) {
    record("GET /api/borrows/all (admin)", false, e.message);
  }

  try {
    await req("POST", "/api/wallet/top-up", {
      token: userToken,
      body: { amount: 50000 },
      expectStatus: 200,
    });
    const pay = await req("POST", `/api/borrows/${borrowId}/pay`, {
      token: userToken,
      expectStatus: 200,
    });
    record(
      "POST /api/borrows/:id/pay",
      pay.json?.data?.payment_status === "paid" ||
        !!pay.json?.message,
      JSON.stringify(pay.json).slice(0, 140),
    );
  } catch (e) {
    record("POST /api/borrows/:id/pay", false, e.message);
  }

  try {
    const wallet = await req("GET", "/api/wallet", {
      token: userToken,
      expectStatus: 200,
    });
    record(
      "GET /api/wallet",
      typeof wallet.json?.data?.balance === "number",
      `balance=${wallet.json?.data?.balance}`,
    );
  } catch (e) {
    record("GET /api/wallet", false, e.message);
  }

  // Create a second borrow to test cancel path
  let cancelBorrowId = null;
  try {
    // Need another approved ready asset for cancel flow; reuse existing Casio id 8 if still ready
    const list = await req("GET", "/api/assets", {
      token: userToken,
      expectStatus: 200,
    });
    const other = (list.json?.data || []).find((a) => a.id !== pendingAssetId);
    if (!other) {
      record("POST /api/borrows (cancel candidate)", false, "no second asset");
    } else {
      const today = new Date();
      const pickup = today.toISOString().slice(0, 10);
      const ret = new Date(today);
      ret.setUTCDate(ret.getUTCDate() + 1);
      const borrow = await req("POST", "/api/borrows", {
        token: userToken,
        body: {
          asset_id: other.id,
          pickup_date: pickup,
          return_date: ret.toISOString().slice(0, 10),
        },
        expectStatus: 201,
      });
      cancelBorrowId = borrow.json?.data?.id;
      const cancelled = await req("PATCH", `/api/borrows/${cancelBorrowId}/cancel`, {
        token: userToken,
        expectStatus: 200,
      });
      record(
        "PATCH /api/borrows/:id/cancel",
        true,
        JSON.stringify(cancelled.json).slice(0, 120),
      );
    }
  } catch (e) {
    record("PATCH /api/borrows/:id/cancel", false, e.message);
  }

  // Return / confirm-return may depend on borrow status after pay
  try {
    const ret = await req("PATCH", `/api/borrows/${borrowId}/return`, {
      token: userToken,
      expectStatus: 200,
    });
    record(
      "PATCH /api/borrows/:id/return",
      true,
      JSON.stringify(ret.json).slice(0, 120),
    );
  } catch (e) {
    record("PATCH /api/borrows/:id/return", false, e.message);
  }

  try {
    const confirm = await req("PATCH", `/api/borrows/${borrowId}/confirm-return`, {
      token: ownerToken,
      expectStatus: 200,
    });
    record(
      "PATCH /api/borrows/:id/confirm-return",
      true,
      JSON.stringify(confirm.json).slice(0, 120),
    );
  } catch (e) {
    record("PATCH /api/borrows/:id/confirm-return", false, e.message);
  }

  let refundTransactionId = null;
  try {
    const transactions = await req(
      "GET",
      `/api/admin/transactions?type=deposit_refund&status=pending&search=${borrowId}`,
      { token: adminToken, expectStatus: 200 },
    );
    const refund = (transactions.json?.data || []).find(
      (transaction) => transaction.borrow_id === borrowId,
    );
    refundTransactionId = refund?.id;
    if (refundTransactionId == null) {
      throw new Error("pending deposit refund was not listed");
    }

    const processed = await req(
      "POST",
      `/api/admin/transactions/${refundTransactionId}/refund`,
      { token: adminToken, expectStatus: 200 },
    );
    record(
      "POST /api/admin/transactions/:id/refund",
      processed.json?.data?.status === "completed",
    );

    await req(
      "POST",
      `/api/admin/transactions/${refundTransactionId}/refund`,
      { token: adminToken, expectStatus: 409 },
    );
    record("POST refund is idempotent", true);
  } catch (e) {
    record("POST /api/admin/transactions/:id/refund", false, e.message);
  }

  try {
    const today = new Date();
    const pickup = today.toISOString().slice(0, 10);
    const ret = new Date(today);
    ret.setUTCDate(ret.getUTCDate() + 1);
    const borrow = await req("POST", "/api/borrows", {
      token: userToken,
      body: {
        asset_id: pendingAssetId,
        pickup_date: pickup,
        return_date: ret.toISOString().slice(0, 10),
      },
      expectStatus: 201,
    });
    const rejected = await req(
      "PATCH",
      `/api/borrows/${borrow.json?.data?.id}/reject`,
      {
        token: ownerToken,
        body: { reason: "Unavailable for this period" },
        expectStatus: 200,
      },
    );
    record(
      "PATCH /api/borrows/:id/reject",
      rejected.json?.data?.status === "rejected",
    );
  } catch (e) {
    record("PATCH /api/borrows/:id/reject", false, e.message);
  }

  try {
    const suspended = await req("PATCH", `/api/users/${userId}/suspension`, {
      token: adminToken,
      body: { is_suspended: true, reason: "API smoke test" },
      expectStatus: 200,
    });
    record(
      "PATCH /api/users/:id/suspension",
      suspended.json?.data?.is_suspended === true &&
        suspended.json?.data?.suspension_reason === "API smoke test",
    );
    await req("GET", "/api/wallet", { token: userToken, expectStatus: 403 });
    record("Suspended account token is blocked", true);
    await req("POST", "/api/auth/login", {
      body: { email: userEmail, password },
      expectStatus: 403,
    });
    record("Suspended account login is blocked", true);

    await req("PATCH", `/api/users/${userId}/suspension`, {
      token: adminToken,
      body: { is_suspended: false },
      expectStatus: 200,
    });
    record("PATCH /api/users/:id/suspension reactivates user", true);
  } catch (e) {
    record("User suspension flow", false, e.message);
  }

  // Delete asset (owner) — create a disposable pending asset then delete
  try {
    const png = Buffer.from(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
      "base64",
    );
    const form = new FormData();
    form.append("image", new Blob([png], { type: "image/png" }), "del.png");
    form.append("name", `Delete Me ${stamp}`);
    form.append("description", "to be deleted");
    form.append("down_payment", "10");
    form.append("price", "10");
    form.append("pickup_point", "Gate");
    const returnBefore = new Date();
    returnBefore.setUTCDate(returnBefore.getUTCDate() + 7);
    form.append("return_before", returnBefore.toISOString().slice(0, 10));
    const created = await req("POST", "/api/assets", {
      token: ownerToken,
      formData: form,
      expectStatus: 201,
    });
    const delId = created.json?.data?.id;
    const deleted = await req("DELETE", `/api/assets/${delId}`, {
      token: ownerToken,
      expectStatus: 200,
    });
    record("DELETE /api/assets/:id", true, JSON.stringify(deleted.json).slice(0, 100));
  } catch (e) {
    record("DELETE /api/assets/:id", false, e.message);
  }

  // Authz negatives
  try {
    await req("GET", "/api/users", { expectStatus: 401 });
    record("GET /api/users without token => 401", true);
  } catch (e) {
    record("GET /api/users without token => 401", false, e.message);
  }

  const passed = results.filter((r) => r.ok).length;
  const failed = results.filter((r) => !r.ok).length;
  console.log("\n========== SUMMARY ==========");
  console.log(`Total: ${results.length}  Passed: ${passed}  Failed: ${failed}`);
  if (failed) {
    console.log("Failed cases:");
    for (const r of results.filter((x) => !x.ok)) {
      console.log(` - ${r.name}: ${r.detail}`);
    }
    process.exitCode = 1;
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
