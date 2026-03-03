const express = require("express");
const router = express.Router();

const adminController = require("../controllers/adminController");
const { verifyToken } = require("../middleware/authMiddleware");
const { isAdmin } = require("../middleware/adminMiddleware");

/////////////////////////////////////////////////
// ADMIN ROUTES
/////////////////////////////////////////////////

router.get("/stats", verifyToken, isAdmin, adminController.getAdminStats);

router.get("/pending-seniors", verifyToken, isAdmin, adminController.getPendingSeniors);
router.get("/pending-volunteers", verifyToken, isAdmin, adminController.getPendingVolunteers);
router.get("/volunteers", verifyToken, isAdmin, adminController.getAllVolunteers);
router.get("/users", verifyToken, isAdmin, adminController.getAllUsers);

router.put("/approve/:userId", verifyToken, isAdmin, adminController.approveUser);
router.put("/reject/:userId", verifyToken, isAdmin, adminController.rejectUser);

module.exports = router;
