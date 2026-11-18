const express = require('express');
const router = express.Router();
const usersController = require('./user_controller');
const authenticateToken = require('../../middlewares/authMiddleware');
const authorizeRoles = require('../../middlewares/roleMiddleware');

router.use(authenticateToken);
router.get('/', authorizeRoles('admin'), usersController.getAllUsers);
router.get('/:id/activities', authorizeRoles('admin'), usersController.getUserActivities);
router.patch('/:id/suspension', authorizeRoles('admin'), usersController.setSuspension);
router.get('/:id', authorizeRoles('admin'), usersController.getUserById);

module.exports = router;