const express = require("express");
const router = express.Router();

const adminController = require("../controllers/adminController");
const { verifyToken } = require("../middleware/authMiddleware");
const { isAdmin } = require("../middleware/adminMiddleware");

router.get("/pending-users", verifyToken, isAdmin, adminController.getPendingUsers);
router.put("/approve/:userId", verifyToken, isAdmin, adminController.approveUser);
router.delete("/reject/:userId", verifyToken, isAdmin, adminController.rejectUser);

module.exports = router;
