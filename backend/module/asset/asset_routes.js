const express = require('express');
const router = express.Router();
const assetsController = require('./asset_controller');
const authenticateToken = require('../../middlewares/authMiddleware');
const authorizeRoles = require('../../middlewares/roleMiddleware');
const { uploadAssetImage } = require('./asset_upload');

router.get('/', authenticateToken.optional, assetsController.getAvailableAssets);

router.use(authenticateToken);
router.post('/', uploadAssetImage, assetsController.createAsset);
router.get('/all', authorizeRoles('admin'), assetsController.getAllAssets);
router.get('/:id', assetsController.getAssetById);
router.delete('/:id', assetsController.deleteAsset);
router.patch('/:id/approve', authorizeRoles('admin'), assetsController.approveAsset);

module.exports = router;