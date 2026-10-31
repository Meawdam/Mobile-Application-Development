const borrowsService = require("./borrow_service");

class BorrowController {
  async getAllBorrows(req, res, next) {
    try {
      const list = await borrowsService.getAllBorrows();
      return res.status(200).json({ data: list });
    } catch (error) {
      next(error);
    }
  }

  async getMyBorrows(req, res, next) {
    try {
      const list = await borrowsService.getMyBorrows(req.user.id);
      return res.status(200).json({ data: list });
    } catch (error) {
      next(error);
    }
  }

  async requestBorrow(req, res, next) {
    try {
      const { asset_id } = req.body;

      if (!asset_id) {
        return res.status(400).json({ message: "Missing required parameters" });
      }

      const result = await borrowsService.requestBorrow(req.user.id, {
        asset_id,
      });

      return res.status(201).json({
        message: "Borrow request submitted successfully",
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async processPayment(req, res, next) {
    try {
      const result = await borrowsService.processPayment(
        req.params.id,
        req.user.id,
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async cancelRequest(req, res, next) {
    try {
      const result = await borrowsService.cancelRequest(
        req.params.id,
        req.user.id,
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async returnAsset(req, res, next) {
    try {
      const result = await borrowsService.returnAsset(
        req.params.id,
        req.user.id,
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async confirmReturn(req, res, next) {
    try {
      const result = await borrowsService.confirmReturn(
        req.params.id,
        req.user.id,
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new BorrowController();
