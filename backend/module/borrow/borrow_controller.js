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

  async getMyLendingBorrows(req, res, next) {
    try {
      const list = await borrowsService.getMyLendingBorrows(req.user.id);
      return res.status(200).json({ data: list });
    } catch (error) {
      next(error);
    }
  }

  async getBorrowById(req, res, next) {
    try {
      const borrow = await borrowsService.getBorrowById(
        req.params.id,
        req.user,
      );
      return res.status(200).json({ data: borrow });
    } catch (error) {
      next(error);
    }
  }

  async requestBorrow(req, res, next) {
    try {
      const { asset_id, pickup_date, return_date } = req.body;

      if (
        asset_id === undefined ||
        asset_id === null ||
        asset_id === "" ||
        typeof pickup_date !== "string" ||
        !pickup_date.trim() ||
        typeof return_date !== "string" ||
        !return_date.trim()
      ) {
        return res.status(400).json({
          message: "asset_id, pickup_date, and return_date are required",
        });
      }

      const result = await borrowsService.requestBorrow(req.user.id, {
        asset_id,
        pickup_date: pickup_date.trim(),
        return_date: return_date.trim(),
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

  async approveRequest(req, res, next) {
    try {
      const result = await borrowsService.approveRequest(
        req.params.id,
        req.user.id,
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async rejectRequest(req, res, next) {
    try {
      const result = await borrowsService.rejectRequest(
        req.params.id,
        req.user.id,
        req.body.reason,
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
