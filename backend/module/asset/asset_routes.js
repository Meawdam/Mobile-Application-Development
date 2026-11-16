const express = require('express');
const router = express.Router();
const assetsController = require('./asset_controller');
const authenticateToken = require('../../middlewares/authMiddleware');
const authorizeRoles = require('../../middlewares/roleMiddleware');
const { uploadAssetImage } = require('./asset_upload');

router.get('/', authenticateToken.optional, assetsController.getAvailableAssets);
router.get(
  '/all',
  authenticateToken,
  authorizeRoles('admin'),
  assetsController.getAllAssets,
);
router.get('/mine', authenticateToken, assetsController.getMyAssets);
router.get('/:id', authenticateToken.optional, assetsController.getAssetById);

router.post(
  '/',
  authenticateToken,
  uploadAssetImage,
  assetsController.createAsset,
);
router.patch('/:id', authenticateToken, assetsController.updateAsset);
router.delete('/:id', authenticateToken, assetsController.deleteAsset);
router.patch(
  '/:id/approve',
  authenticateToken,
  authorizeRoles('admin'),
  assetsController.approveAsset,
);

module.exports = router;
