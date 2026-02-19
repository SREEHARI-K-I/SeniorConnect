const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const { createRateLimiter } = require("../middleware/rateLimitMiddleware");

const otpSendLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  max: 8,
  keyFn: (req) => `${req.ip}:send:${String(req.body?.phone || "").replace(/\D/g, "")}`,
  message: "Too many OTP requests. Please try again later."
});

const otpVerifyLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  max: 12,
  keyFn: (req) => `${req.ip}:verify:${String(req.body?.phone || "").replace(/\D/g, "")}`,
  message: "Too many OTP verification attempts. Please try again later."
});

const adminLoginLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 6,
  keyFn: (req) => `${req.ip}:admin:${String(req.body?.phone || "").replace(/\D/g, "")}`,
  message: "Too many admin login attempts. Please try again later."
});

// Registration (Senior / Volunteer)
router.post("/register-senior", authController.registerSenior);
router.post("/register-volunteer", authController.registerVolunteer);
router.post("/verify-register-otp", otpVerifyLimiter, authController.verifyRegisterOtp);

// Senior/Volunteer login flow
router.post("/login/send-otp", otpSendLimiter, authController.userLoginStep1);
router.post("/login/verify-otp", otpVerifyLimiter, authController.userLoginStep2);

// Admin login flow
router.post("/admin/login/send-otp", adminLoginLimiter, otpSendLimiter, authController.adminLoginStep1);
router.post("/admin/login/verify-otp", adminLoginLimiter, otpVerifyLimiter, authController.adminLoginStep2);

// Backward-compatible aliases (do not remove until Flutter is updated)
router.post("/register", authController.registerSenior);
router.post("/verify-otp", otpVerifyLimiter, authController.verifyRegisterOtp);
router.post("/login", otpSendLimiter, authController.userLoginStep1);
router.post("/login-verify-otp", otpVerifyLimiter, authController.userLoginStep2);

module.exports = router;
