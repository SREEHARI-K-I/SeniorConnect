const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");

// Registration
router.post("/register-senior", authController.registerSenior);
router.post("/register-volunteer", authController.registerVolunteer);
router.post("/verify-register-otp", authController.verifyRegisterOtp);

// User login OTP flow
router.post("/login/send-otp", authController.userLoginStep1);
router.post("/login/verify-otp", authController.userLoginStep2);

// Admin login OTP flow
router.post("/admin/login/send-otp", authController.adminLoginStep1);
router.post("/admin/login/verify-otp", authController.adminLoginStep2);

// Backward-compatible aliases
router.post("/login-otp", authController.loginOtpStep1);
router.post("/login-verify-otp", authController.loginOtpStep2);
router.post("/admin-login", authController.adminLoginStep1);
router.post("/admin-verify-otp", authController.adminLoginStep2);

module.exports = router;

