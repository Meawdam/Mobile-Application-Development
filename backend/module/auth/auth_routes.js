const express = require("express");
const router = express.Router();
const authController = require("./auth_controller");
const authenticateToken = require("../../middlewares/authMiddleware");

router.post("/register", authController.register);
router.post("/login", authController.login);
router.get("/me", authenticateToken, authController.getProfile);

module.exports = router;