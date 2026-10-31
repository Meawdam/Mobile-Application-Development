const express = require('express');
const router = express.Router();
const assetsController = require('./assets.controller');
const authenticateToken = require('../../middlewares/authMiddleware');
const authorizeRoles = require('../../middlewares/roleMiddleware');

router.get('/', assetsController.getAvailableAssets);

router.use(authenticateToken);
router.post('/', assetsController.createAsset);
router.delete('/:id', assetsController.deleteAsset);

router.get('/all', authorizeRoles('admin'), assetsController.getAllAssets);
router.get('/:id', assetsController.getAssetById);
router.patch('/:id/approve', authorizeRoles('admin'), assetsController.approveAsset);

module.exports = router;