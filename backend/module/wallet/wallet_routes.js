const express = require("express");
const router = express.Router();
const walletController = require("./wallet_controller");
const authenticateToken = require("../../middlewares/authMiddleware");

router.use(authenticateToken);
router.get("/", walletController.getWallet);
router.post("/top-up", walletController.topUp);

module.exports = router;
