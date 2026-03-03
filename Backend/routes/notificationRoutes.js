const express = require("express");
const router = express.Router();

const notificationController = require("../controllers/notificationController");
const { verifyToken } = require("../middleware/authMiddleware");
const { createRateLimiter } = require("../middleware/rateLimitMiddleware");

const tokenLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  max: 40,
  keyFn: (req) => `${req.ip}:notify-token:${req.user?.id || "anon"}`,
  message: "Too many token updates. Please try again later."
});

router.post("/device-token", verifyToken, tokenLimiter, notificationController.upsertDeviceToken);
router.delete("/device-token", verifyToken, tokenLimiter, notificationController.deleteDeviceToken);

module.exports = router;

