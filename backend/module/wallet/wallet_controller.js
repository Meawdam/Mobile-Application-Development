const walletService = require("./wallet_service");

class WalletController {
  async getWallet(req, res, next) {
    try {
      const wallet = await walletService.getWallet(req.user.id);
      return res.status(200).json({ data: wallet });
    } catch (error) {
      next(error);
    }
  }

  async topUp(req, res, next) {
    try {
      const { amount } = req.body;
      if (amount === undefined || amount === null || amount === "") {
        return res.status(400).json({ message: "amount is required" });
      }

      const result = await walletService.topUp(req.user.id, amount);
      return res.status(200).json({
        message: "Wallet topped up successfully",
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new WalletController();
