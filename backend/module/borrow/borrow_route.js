const express = require("express");
const router = express.Router();
const borrowsController = require("./borrow_controller");
const assetsController = require("../asset/asset_controller");
const authenticateToken = require("../../middlewares/authMiddleware");
const authorizeRoles = require("../../middlewares/roleMiddleware");

router.use(authenticateToken);
router.get("/all", authorizeRoles("admin"), borrowsController.getAllBorrows);
router.get("/my", borrowsController.getMyBorrows);
router.get("/owner", borrowsController.getMyLendingBorrows);
router.get("/lending", borrowsController.getMyLendingBorrows);
router.get("/assets/:id", assetsController.getAssetById);
router.get("/:id", borrowsController.getBorrowById);
router.post("/", borrowsController.requestBorrow);
router.patch("/:id/approve", borrowsController.approveRequest);
router.patch("/:id/reject", borrowsController.rejectRequest);
router.patch("/:id/cancel", borrowsController.cancelRequest);
router.post("/:id/pay", borrowsController.processPayment);
router.patch("/:id/confirm-received", borrowsController.confirmReceived);
router.patch("/:id/return", borrowsController.returnAsset);
router.patch("/:id/confirm-return", borrowsController.confirmReturn);

module.exports = router;
