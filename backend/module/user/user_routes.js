const express = require('express');
const router = express.Router();
const usersController = require('./users.controller');
const authenticateToken = require('../../middlewares/authMiddleware');
const authorizeRoles = require('../../middlewares/roleMiddleware');

router.use(authenticateToken);

router.get('/', authorizeRoles('admin'), usersController.getAllUsers);
router.get('/:id', authorizeRoles('admin'), usersController.getUserById);

module.exports = router;