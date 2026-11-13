const walletRepository = require("./wallet_repository");
const {
  amountCentsToNumber,
  formatAmountCents,
  parseAmountCents,
} = require("../../utils/money_utils");

const MAX_TOP_UP_AMOUNT_CENTS = 100_000_000;

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
    const amountCents = parseAmountCents(amount);
    if (amountCents === null || amountCents <= 0) {
      const err = new Error(
        "amount must be positive with at most 2 decimal places",
      );
      err.status = 400;
      throw err;
    }
    if (amountCents > MAX_TOP_UP_AMOUNT_CENTS) {
      const err = new Error("amount exceeds the maximum top-up limit");
      err.status = 400;
      throw err;
    }

    const balance = await walletRepository.topUp(
      userId,
      formatAmountCents(amountCents),
    );
    return { balance, topped_up: amountCentsToNumber(amountCents) };
  }
}

module.exports = new WalletService();
