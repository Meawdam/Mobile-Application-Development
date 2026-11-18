/**
 * @swagger
 * tags:
 *   - name: Wallet
 *     description: User wallet balance and top-ups used for borrow payments
 * components:
 *   schemas:
 *     Wallet:
 *       type: object
 *       properties:
 *         balance:
 *           type: number
 *           format: double
 *           example: 5000.50
 *     WalletResponse:
 *       type: object
 *       properties:
 *         data:
 *           $ref: '#/components/schemas/Wallet'
 *     WalletTopUpRequest:
 *       type: object
 *       required: [amount]
 *       properties:
 *         amount:
 *           type: number
 *           format: double
 *           minimum: 0.01
 *           maximum: 1000000
 *           example: 1000.50
 */

/**
 * @swagger
 * /api/wallet:
 *   get:
 *     tags: [Wallet]
 *     summary: Get the authenticated user's wallet balance
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Current wallet balance
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/WalletResponse'
 *       401:
 *         description: Access token is required
 */

/**
 * @swagger
 * /api/wallet/top-up:
 *   post:
 *     tags: [Wallet]
 *     summary: Add funds to the authenticated user's wallet
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/WalletTopUpRequest'
 *     responses:
 *       200:
 *         description: Wallet topped up
 *       400:
 *         description: Invalid amount
 *       401:
 *         description: Access token is required
 */
