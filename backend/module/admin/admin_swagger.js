/**
 * @swagger
 * tags:
 *   - name: Admin
 *     description: Admin dashboard and financial transaction management
 */

/**
 * @swagger
 * /api/admin/dashboard:
 *   get:
 *     tags: [Admin]
 *     summary: Get dashboard summary
 *     description: Admin-only totals for assets, recent borrow volume, and finance.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard summary retrieved
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not an admin
 */

/**
 * @swagger
 * /api/admin/transactions:
 *   get:
 *     tags: [Admin]
 *     summary: List financial transactions
 *     description: Admin-only transaction ledger with optional filters and pagination.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [wallet_top_up, rental_payment, deposit_hold, fine_collected, deposit_refund]
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, completed, released]
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *           maxLength: 100
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 50
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           minimum: 0
 *           default: 0
 *     responses:
 *       200:
 *         description: Transactions retrieved
 *       400:
 *         description: Invalid filter or pagination values
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not an admin
 */

/**
 * @swagger
 * /api/admin/transactions/{id}/refund:
 *   post:
 *     tags: [Admin]
 *     summary: Process a pending deposit refund
 *     description: Credits the borrower's wallet once, after the asset owner has confirmed the return.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Refund processed
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not an admin
 *       404:
 *         description: Refund transaction not found
 *       409:
 *         description: Refund is no longer pending
 */
