const assetService = require("./asset_service");
const { removeFile } = require("./asset_upload");

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
      const { name, description, down_payment, return_before } = req.body;

      if (
        typeof name !== "string" ||
        !name.trim() ||
        typeof description !== "string" ||
        !description.trim() ||
        down_payment === undefined ||
        down_payment === "" ||
        typeof return_before !== "string" ||
        !return_before.trim()
      ) {
        await removeFile(req.file.path);
        return res
          .status(400)
          .json({
            message:
              "name, description, image, down_payment, and return_before are required",
          });
      }

      const newAsset = await assetService.createAsset(req.user.id, {
        name: name.trim(),
        description: description.trim(),
        image: `/uploads/${req.file.filename}`,
        down_payment,
        return_before: return_before.trim(),
      });

      return res.status(201).json({
        message: "Asset submitted for admin approval",
        data: newAsset,
      });
    } catch (error) {
      try {
        await removeFile(req.file.path);
      } catch (cleanupError) {
        console.error("Failed to remove uploaded image after asset creation failed:", cleanupError);
      }
      next(error);
    }
  }

  async approveAsset(req, res, next) {
    try {
      const { approval, approval_message } = req.body;

      if (!["approved", "not approve"].includes(approval)) {
        return res.status(400).json({
          message: "Approval status must be approved or not approve",
        });
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