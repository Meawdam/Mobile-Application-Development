/**
 * @swagger
 * tags:
 *   - name: Users
 *     description: Admin-only user lookup endpoints
 * components:
 *   schemas:
 *     UserRecord:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           example: 1
 *         username:
 *           type: string
 *           example: jane_doe
 *         email:
 *           type: string
 *           format: email
 *           example: jane@example.com
 *         phone_num:
 *           type: string
 *           maxLength: 10
 *           example: '0812345678'
 *         role:
 *           type: string
 *           example: user
 *         is_suspended:
 *           type: boolean
 *           example: false
 *         suspension_reason:
 *           type: string
 *           nullable: true
 *           example: Repeatedly cancelled paid requests
 *         total_records:
 *           type: integer
 *           example: 10
 *         lending:
 *           type: integer
 *           example: 6
 *         overdue:
 *           type: integer
 *           example: 1
 *     UserListResponse:
 *       type: object
 *       properties:
 *         data:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/UserRecord'
 *     UserResponse:
 *       type: object
 *       properties:
 *         data:
 *           $ref: '#/components/schemas/UserRecord'
 *     UserSuspension:
 *       type: object
 *       required: [is_suspended]
 *       properties:
 *         is_suspended:
 *           type: boolean
 *           example: true
 *         reason:
 *           type: string
 *           maxLength: 500
 *           example: Repeatedly cancelled paid requests
 */

/**
 * @swagger
 * /api/users:
 *   get:
 *     tags: [Users]
 *     summary: Get all users
 *     description: Requires a valid JWT belonging to an admin.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Users retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/UserListResponse'
 *       401:
 *         description: Access token is required
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       403:
 *         description: Token is invalid or the user is not an admin
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

/**
 * @swagger
 * /api/users/{id}:
 *   get:
 *     tags: [Users]
 *     summary: Get a user by ID
 *     description: Requires a valid JWT belonging to an admin.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID of the user to retrieve
 *         schema:
 *           type: integer
 *           example: 1
 *     responses:
 *       200:
 *         description: User retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/UserResponse'
 *       401:
 *         description: Access token is required
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       403:
 *         description: Token is invalid or the user is not an admin
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: User not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

/**
 * @swagger
 * /api/users/{id}/suspension:
 *   patch:
 *     tags: [Users]
 *     summary: Suspend or reactivate a user account
 *     description: Admin-only. A reason is required when suspending; reactivation clears the reason.
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
 *             $ref: '#/components/schemas/UserSuspension'
 *     responses:
 *       200:
 *         description: Account status updated
 *       400:
 *         description: Invalid status or missing/oversized reason
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not an admin
 *       404:
 *         description: User not found
 */

/**
 * @swagger
 * /api/users/{id}/activities:
 *   get:
 *     tags: [Users]
 *     summary: Get a user's activity history
 *     description: Admin-only. Filter by rental, finance, or admin activity.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [rental, finance, admin]
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
 *         description: User activities retrieved
 *       400:
 *         description: Invalid category or pagination values
 *       401:
 *         description: Access token is required
 *       403:
 *         description: Token is invalid or the user is not an admin
 *       404:
 *         description: User not found
 */
