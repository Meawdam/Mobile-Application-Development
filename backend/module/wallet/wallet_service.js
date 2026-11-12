const walletRepository = require("./wallet_repository");

class WalletService {
  async getWallet(userId) {
    const balance = await walletRepository.getBalance(userId);
    if (balance === null) {
      const err = new Error("User not found");
      err.status = 404;
      throw err;
    }
    return { balance };
  }

  async topUp(userId, amount) {
    const value = Number(amount);
    if (!Number.isSafeInteger(value) || value <= 0) {
      const err = new Error("amount must be a positive whole number");
      err.status = 400;
      throw err;
    }
    if (value > 1000000) {
      const err = new Error("amount exceeds the maximum top-up limit");
      err.status = 400;
      throw err;
    }

    const balance = await walletRepository.topUp(userId, value);
    return { balance, topped_up: value };
  }
}

module.exports = new WalletService();
