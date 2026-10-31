const express = require('express');
const router = express.Router();
const assetsController = require('./asset_controller');
const authenticateToken = require('../../middlewares/authMiddleware');
const authorizeRoles = require('../../middlewares/roleMiddleware');
const { uploadAssetImage } = require('./asset_upload');

/**
 * @swagger
 * tags:
 *   - name: Assets
 *     description: Browse and manage assets
 * components:
 *   schemas:
 *     Asset:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           example: 1
 *         owner_id:
 *           type: integer
 *           example: 7
 *         name:
 *           type: string
 *           example: Camera
 *         description:
 *           type: string
 *           example: Mirrorless camera in good condition
 *         image:
 *           type: string
 *           description: Public URL path for the uploaded image
 *           example: /uploads/08ab835d-f75d-4c19-89f2-808a210f18c6.jpg
 *         down_payment:
 *           type: number
 *           example: 250
 *         status:
 *           type: string
 *           example: ready
 *         approval:
 *           type: string
 *           example: approved
 *         approval_message:
 *           type: string
 *           nullable: true
 *           example: Approved
 *     AssetListResponse:
 *       type: object
 *       properties:
 *         data:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/Asset'
 *     AssetResponse:
 *       type: object
 *       properties:
 *         data:
 *           $ref: '#/components/schemas/Asset'
 *     AssetError:
 *       type: object
 *       properties:
 *         message:
 *           type: string
 *           example: Asset not found
 */

/**
 * @swagger
 * /api/assets:
 *   get:
 *     tags: [Assets]
 *     summary: Get available assets
 *     description: Returns approved assets that are ready.
 *     responses:
 *       200:
 *         description: Available assets
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/AssetListResponse'
 */
router.get('/', assetsController.getAvailableAssets);

router.use(authenticateToken);

/**
 * @swagger
 * /api/assets:
 *   post:
 *     tags: [Assets]
 *     summary: Submit an asset for approval
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required: [name, description, image, down_payment]
 *             properties:
 *               name:
 *                 type: string
 *                 example: Camera
 *               description:
 *                 type: string
 *                 example: Mirrorless camera in good condition
 *               image:
 *                 type: string
 *                 format: binary
 *                 description: JPEG, PNG, GIF, or WebP image up to 5 MB
 *               down_payment:
 *                 type: number
 *                 example: 250
 *     responses:
 *       201:
 *         description: Asset submitted for admin approval
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Asset submitted for admin approval
 *                 data:
 *                   $ref: '#/components/schemas/Asset'
 *       400:
 *         description: Required fields are missing, image is missing, or the image format is unsupported
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/AssetError'
 *       401:
 *         description: Access token is required
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       403:
 *         description: Token is invalid
 *       413:
 *         description: Image exceeds the 5 MB upload limit
 */
router.post('/', uploadAssetImage, assetsController.createAsset);

/**
 * @swagger
 * /api/assets/all:
 *   get:
 *     tags: [Assets]
 *     summary: Get all assets
 *     description: Admin-only endpoint. Includes assets regardless of approval status.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: All assets
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/AssetListResponse'
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not an admin
 */
router.get('/all', authorizeRoles('admin'), assetsController.getAllAssets);

/**
 * @swagger
 * /api/assets/{id}:
 *   get:
 *     tags: [Assets]
 *     summary: Get an asset by ID
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID of the asset
 *         schema:
 *           type: integer
 *           example: 1
 *     responses:
 *       200:
 *         description: Asset details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/AssetResponse'
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid
 *       404:
 *         description: Asset not found
 */
router.get('/:id', assetsController.getAssetById);

/**
 * @swagger
 * /api/assets/{id}:
 *   delete:
 *     tags: [Assets]
 *     summary: Delete an asset owned by the authenticated user
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID of the asset
 *         schema:
 *           type: integer
 *           example: 1
 *     responses:
 *       200:
 *         description: Asset deleted successfully
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the asset belongs to another user
 *       404:
 *         description: Asset not found
 */
router.delete('/:id', assetsController.deleteAsset);

/**
 * @swagger
 * /api/assets/{id}/approve:
 *   patch:
 *     tags: [Assets]
 *     summary: Approve or reject an asset
 *     description: Admin-only endpoint.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID of the asset
 *         schema:
 *           type: integer
 *           example: 1
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [approval]
 *             properties:
 *               approval:
 *                 type: string
 *                 enum: [approved, rejected]
 *                 example: approved
 *               approval_message:
 *                 type: string
 *                 example: Meets the listing requirements
 *     responses:
 *       200:
 *         description: Asset approval status updated
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Asset approval status updated
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     approval:
 *                       type: string
 *                     approval_message:
 *                       type: string
 *       400:
 *         description: Approval status is required
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not an admin
 *       404:
 *         description: Asset not found
 */
router.patch('/:id/approve', authorizeRoles('admin'), assetsController.approveAsset);

module.exports = router;