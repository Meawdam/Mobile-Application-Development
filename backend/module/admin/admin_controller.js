const adminService = require("./admin_service");

class AdminController {
  async getDashboard(req, res, next) {
    try {
      const dashboard = await adminService.getDashboard();
      return res.status(200).json({ data: dashboard });
    } catch (error) {
      next(error);
    }
  }

  async getTransactions(req, res, next) {
    try {
      const result = await adminService.getTransactions(req.query);
      return res.status(200).json({ data: result.transactions, pagination: result.pagination });
    } catch (error) {
      next(error);
    }
  }

  async processRefund(req, res, next) {
    try {
      const result = await adminService.processRefund(
        req.params.id,
        req.user.id,
      );
      return res.status(200).json({
        message: "Deposit refund processed",
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AdminController();
