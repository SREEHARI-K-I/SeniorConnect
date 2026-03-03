const express = require("express");
const router = express.Router();

const requestController = require("../controllers/requestController");
const { verifyToken } = require("../middleware/authMiddleware");
const { createRateLimiter } = require("../middleware/rateLimitMiddleware");

const actionLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  max: 40,
  keyFn: (req) => `${req.ip}:ambulance:${req.user?.id || "anon"}`,
  message: "Too many ambulance actions. Please slow down."
});

router.get("/requests", verifyToken, requestController.getVolunteerRequests);
router.put("/requests/:requestId/accept", verifyToken, actionLimiter, requestController.acceptRequest);
router.put("/requests/:requestId/reject", verifyToken, actionLimiter, requestController.rejectRequest);
router.put("/requests/:requestId/complete", verifyToken, actionLimiter, requestController.completeRequest);

router.get("/history", verifyToken, requestController.getVolunteerHistory);
router.get("/availability", verifyToken, requestController.getVolunteerAvailability);
router.put("/availability", verifyToken, actionLimiter, requestController.updateVolunteerAvailability);

module.exports = router;

