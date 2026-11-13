/**
 * @swagger
 * tags:
 *   - name: Borrows
 *     description: Borrow requests, payments, and asset returns
 * components:
 *   schemas:
 *     Borrow:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           example: 12
 *         asset_id:
 *           type: integer
 *           example: 4
 *         asset_name:
 *           type: string
 *           example: Camera
 *         asset_image:
 *           type: string
 *           example: /uploads/camera.jpg
 *         borrower_id:
 *           type: integer
 *           example: 7
 *         borrower_name:
 *           type: string
 *           example: jane_doe
 *         owner_name:
 *           type: string
 *           example: alex
 *         pickup_date:
 *           type: string
 *           format: date
 *           description: Borrower-selected pickup date (must be within lending_end_date)
 *           example: '2026-11-02'
 *         planned_return_date:
 *           type: string
 *           format: date
 *           description: Borrower-selected return date (must be within lending_end_date)
 *           example: '2026-11-05'
 *         rental_days:
 *           type: integer
 *           description: Inclusive day count between pickup_date and planned_return_date
 *           example: 4
 *         borrow_date:
 *           type: string
 *           format: date
 *           description: Set from pickup_date when the borrow request is paid
 *           example: '2026-11-02'
 *         lending_end_date:
 *           type: string
 *           format: date
 *           description: The asset's lending end date set by its owner (return_before)
 *           example: '2026-11-08'
 *         return_date:
 *           type: string
 *           format: date-time
 *           description: Set when the owner confirms the return
 *           nullable: true
 *         status:
 *           type: string
 *           enum: [requested, approved, borrowed, returned_pending, returned_confirmed, rejected]
 *           description: rejected includes borrow requests cancelled by the borrower
 *           example: requested
 *         payment_status:
 *           type: string
 *           enum: [unpaid, paid, refunded, forfeited]
 *           example: unpaid
 *     BorrowListResponse:
 *       type: object
 *       properties:
 *         data:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/Borrow'
 *     BorrowRequest:
 *       type: object
 *       required: [asset_id, pickup_date, return_date]
 *       properties:
 *         asset_id:
 *           type: integer
 *           example: 4
 *         pickup_date:
 *           type: string
 *           format: date
 *           example: '2026-11-02'
 *         return_date:
 *           type: string
 *           format: date
 *           example: '2026-11-05'
 */

/**
 * @swagger
 * /api/borrows/all:
 *   get:
 *     tags: [Borrows]
 *     summary: Get all borrow records
 *     description: Admin-only endpoint.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: All borrow records
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/BorrowListResponse'
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not an admin
 */

/**
 * @swagger
 * /api/borrows/my:
 *   get:
 *     tags: [Borrows]
 *     summary: Get the authenticated user's borrow records
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Borrow records for the authenticated user
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/BorrowListResponse'
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid
 */

/**
 * @swagger
 * /api/borrows:
 *   post:
 *     tags: [Borrows]
 *     summary: Request to borrow an asset
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/BorrowRequest'
 *     responses:
 *       201:
 *         description: Borrow request submitted
 *       400:
 *         description: Required parameters are missing, the asset is unavailable, or the user owns the asset
 *       409:
 *         description: The asset was reserved by another borrow request
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid
 *       404:
 *         description: Asset not found
 */

/**
 * @swagger
 * /api/borrows/{id}/pay:
 *   post:
 *     tags: [Borrows]
 *     summary: Pay for a borrow request
 *     description: The authenticated user must be the borrower.
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
 *         description: Payment completed and asset marked as borrowed
 *       400:
 *         description: Borrow request is no longer awaiting payment
 *       409:
 *         description: Reserved asset is no longer available
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not the borrower
 *       404:
 *         description: Borrow record not found
 */

/**
 * @swagger
 * /api/borrows/{id}/cancel:
 *   patch:
 *     tags: [Borrows]
 *     summary: Cancel an unpaid borrow request
 *     description: The authenticated user must be the borrower. Only requests that have not been paid can be cancelled.
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
 *         description: Borrow request cancelled
 *       400:
 *         description: Only unpaid borrow requests can be cancelled
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not the borrower
 *       404:
 *         description: Borrow record not found
 *       409:
 *         description: Borrow request is no longer available to cancel
 */

/**
 * @swagger
 * /api/borrows/{id}/approve:
 *   patch:
 *     tags: [Borrows]
 *     summary: Approve an unpaid borrow request
 *     description: The authenticated user must own the asset. Borrowers may still pay immediately before this action.
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
 *         description: Borrow request approved
 *       400:
 *         description: Request is no longer awaiting a decision
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not the asset owner
 *       404:
 *         description: Borrow record not found
 *       409:
 *         description: Request changed before the decision was saved
 */

/**
 * @swagger
 * /api/borrows/{id}/reject:
 *   patch:
 *     tags: [Borrows]
 *     summary: Reject an unpaid borrow request
 *     description: The authenticated user must own the asset; a rejection reason is required.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [reason]
 *             properties:
 *               reason:
 *                 type: string
 *                 maxLength: 500
 *     responses:
 *       200:
 *         description: Borrow request rejected
 *       400:
 *         description: Invalid or missing rejection reason
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not the asset owner
 *       404:
 *         description: Borrow record not found
 *       409:
 *         description: Request changed before the decision was saved
 */

/**
 * @swagger
 * /api/borrows/{id}/return:
 *   patch:
 *     tags: [Borrows]
 *     summary: Request to return a borrowed asset
 *     description: The authenticated user must be the borrower.
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
 *         description: Return request submitted for owner confirmation, including after the return-by date
 *       400:
 *         description: The item has already been returned, a return request is already pending, or the item is not borrowed
 *       409:
 *         description: The borrow is no longer eligible for return
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not the borrower
 *       404:
 *         description: Borrow record not found
 */

/**
 * @swagger
 * /api/borrows/{id}/confirm-return:
 *   patch:
 *     tags: [Borrows]
 *     summary: Confirm an asset return
 *     description: The authenticated user must own the borrowed asset.
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
 *         description: Return confirmed; the deposit is refunded after admin processing or forfeited to the owner if the return deadline passed
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 deposit_forfeited:
 *                   type: integer
 *                 refund_pending:
 *                   type: integer
 *       400:
 *         description: The item has already been returned or no return request is pending
 *       409:
 *         description: Return request is no longer awaiting confirmation
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not the asset owner
 *       404:
 *         description: Borrow record not found
 */
