const express = require("express");
const router = express.Router();
const borrowsController = require("./borrow_controller");
const authenticateToken = require("../../middlewares/authMiddleware");
const authorizeRoles = require("../../middlewares/roleMiddleware");

router.use(authenticateToken);
router.get("/all", authorizeRoles("admin"), borrowsController.getAllBorrows);
router.get("/my", borrowsController.getMyBorrows);
router.post("/", borrowsController.requestBorrow);
router.post("/:id/pay", borrowsController.processPayment);
router.patch("/:id/return", borrowsController.returnAsset);
router.patch("/:id/confirm-return", borrowsController.confirmReturn);

module.exports = router;
