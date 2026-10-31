const assetService = require("./asset_service");

class AssetsController {
  async getAvailableAssets(req, res, next) {
    try {
      const assets = await assetService.getAvailableAsset();
      return res.status(200).json({ data: assets });
    } catch (error) {
      next(error);
    }
  }

  async getAllAssets(req, res, next) {
    try {
      const assets = await assetService.getAllAsset();
      return res.status(200).json({ data: assets });
    } catch (error) {
      next(error);
    }
  }

  async getAssetById(req, res, next) {
    try {
      const asset = await assetService.getAssetById(req.params.id);
      return res.status(200).json({ data: asset });
    } catch (error) {
      next(error);
    }
  }

  async createAsset(req, res, next) {
    try {
      const { name, description, image, down_payment } = req.body;

      if (!name || down_payment === undefined) {
        return res
          .status(400)
          .json({ message: "Name and down_payment are required" });
      }

      const newAsset = await assetService.createAsset(req.user.id, {
        name,
        description,
        image,
        down_payment,
      });

      return res.status(201).json({
        message: "Asset submitted for admin approval",
        data: newAsset,
      });
    } catch (error) {
      next(error);
    }
  }

  async approveAsset(req, res, next) {
    try {
      const { approval, approval_message } = req.body;

      if (!approval) {
        return res.status(400).json({ message: "Approval status is required" });
      }

      const result = await assetService.approveAsset(req.params.id, {
        approval,
        approval_message,
      });

      return res.status(200).json({
        message: "Asset approval status updated",
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async deleteAsset(req, res, next) {
    try {
      const result = await assetService.deleteAsset(
        req.params.id,
        req.user.id,
      );
      return res.status(200).json({
        message: "Asset deleted successfully",
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AssetsController();