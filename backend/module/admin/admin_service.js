const adminRepository = require("./admin_repository");

const transactionTypes = new Set([
  "wallet_top_up",
  "rental_payment",
  "deposit_hold",
  "fine_collected",
  "deposit_refund",
]);
const transactionStatuses = new Set(["pending", "completed", "released"]);

class AdminService {
  async getDashboard() {
    return adminRepository.getDashboard();
  }

  async getTransactions({ type, status, search, limit = 50, offset = 0 } = {}) {
    if (type && !transactionTypes.has(type)) {
      const err = new Error("Unsupported transaction type");
      err.status = 400;
      throw err;
    }
    if (status && !transactionStatuses.has(status)) {
      const err = new Error("status must be pending, completed, or released");
      err.status = 400;
      throw err;
    }
    const parsedLimit = Number(limit);
    const parsedOffset = Number(offset);
    if (
      !Number.isSafeInteger(parsedLimit) ||
      parsedLimit < 1 ||
      parsedLimit > 100 ||
      !Number.isSafeInteger(parsedOffset) ||
      parsedOffset < 0
    ) {
      const err = new Error("limit must be 1-100 and offset must be non-negative");
      err.status = 400;
      throw err;
    }
    if (search !== undefined && typeof search !== "string") {
      const err = new Error("search must be a string");
      err.status = 400;
      throw err;
    }
    const normalizedSearch = search?.trim();
    if (normalizedSearch && normalizedSearch.length > 100) {
      const err = new Error("search must not exceed 100 characters");
      err.status = 400;
      throw err;
    }

    const result = await adminRepository.findTransactions({
      type,
      status,
      search: normalizedSearch,
      limit: parsedLimit,
      offset: parsedOffset,
    });
    return {
      transactions: result.rows,
      pagination: {
        limit: parsedLimit,
        offset: parsedOffset,
        total: result.total,
      },
    };
  }

  async processRefund(id, adminId) {
    const transactionId = Number(id);
    if (!Number.isSafeInteger(transactionId) || transactionId <= 0) {
      const err = new Error("Transaction ID must be a positive integer");
      err.status = 400;
      throw err;
    }
    const result = await adminRepository.processRefund(transactionId, adminId);
    if (!result) {
      const err = new Error("Refund transaction not found");
      err.status = 404;
      throw err;
    }
    if (result === false) {
      const err = new Error("Refund is no longer pending");
      err.status = 409;
      throw err;
    }
    return result;
  }
}

module.exports = new AdminService();
