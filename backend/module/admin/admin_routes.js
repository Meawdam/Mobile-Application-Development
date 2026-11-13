const express = require("express");
const adminController = require("./admin_controller");
const authenticateToken = require("../../middlewares/authMiddleware");
const authorizeRoles = require("../../middlewares/roleMiddleware");

const router = express.Router();

router.use(authenticateToken, authorizeRoles("admin"));
router.get("/dashboard", adminController.getDashboard);
router.get("/transactions", adminController.getTransactions);
router.post("/transactions/:id/refund", adminController.processRefund);

module.exports = router;
