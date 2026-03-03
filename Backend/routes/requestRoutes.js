const express = require("express");
const router = express.Router();

const requestController = require("../controllers/requestController");
const { verifyToken } = require("../middleware/authMiddleware");
const { createRateLimiter } = require("../middleware/rateLimitMiddleware");

const requestCreateLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  max: 10,
  keyFn: (req) => `${req.ip}:req:create:${req.user?.id || "anon"}`,
  message: "Too many request submissions. Please try again later."
});

const emergencyCreateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  max: 8,
  keyFn: (req) => `${req.ip}:req:emergency:${req.user?.id || "anon"}`,
  message: "Too many emergency alerts. Please wait a moment."
});

router.post("/", verifyToken, requestCreateLimiter, requestController.createRequest);
router.post("/emergency", verifyToken, emergencyCreateLimiter, requestController.createEmergencyRequest);
router.get("/my", verifyToken, requestController.getMyRequests);
router.get("/volunteers/available", verifyToken, requestController.getAvailableVolunteers);

module.exports = router;
