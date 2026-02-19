const crypto = require("crypto");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const db = require("../config/db");

const OTP_EXPIRY_MINUTES = 5;
const PHONE_REGEX = /^\d{10,15}$/;
const OTP_REGEX = /^\d{6}$/;

function dbQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, result) => {
      if (err) return reject(err);
      resolve(result);
    });
  });
}

function normalizePhone(phone) {
  return String(phone || "").replace(/\D/g, "");
}

function isValidPhone(phone) {
  return PHONE_REGEX.test(phone);
}

function isValidOtp(otp) {
  return OTP_REGEX.test(String(otp || ""));
}

function otpExpiryDate() {
  return new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);
}

function generateOtp() {
  return crypto.randomInt(100000, 1000000).toString();
}

function otpSecret() {
  return process.env.OTP_SECRET || process.env.JWT_SECRET;
}

function hashOtp(otp) {
  return crypto.createHmac("sha256", otpSecret()).update(otp).digest("hex");
}

function safeEqual(a, b) {
  const left = Buffer.from(String(a || ""));
  const right = Buffer.from(String(b || ""));

  if (left.length !== right.length) return false;
  return crypto.timingSafeEqual(left, right);
}

function shouldReturnOtpForTesting() {
  return process.env.NODE_ENV !== "production";
}

function sendOtpResponse(res, message, otp) {
  const payload = { message };
  if (shouldReturnOtpForTesting()) {
    payload.otp = otp;
  }
  return res.json(payload);
}

function createJwt(user) {
  return jwt.sign(
    { id: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: "7d", algorithm: "HS256" }
  );
}

async function getUserByPhone(phone) {
  const result = await dbQuery(
    `SELECT id,name,phone,age,gender,ward,panchayat,house_number,house_name,pincode,
            health_issues,occupation,role,status,otp,otp_expiry,is_verified,password_hash
     FROM users
     WHERE phone = ?
     LIMIT 1`,
    [phone]
  );

  return result.length ? result[0] : null;
}

async function setOtp(phone, otp) {
  await dbQuery(
    "UPDATE users SET otp = ?, otp_expiry = ? WHERE phone = ?",
    [hashOtp(otp), otpExpiryDate(), phone]
  );
}

async function clearOtp(phone) {
  await dbQuery("UPDATE users SET otp = NULL, otp_expiry = NULL WHERE phone = ?", [phone]);
}

function validateOtp(user, otp) {
  if (!user.otp) {
    return "Invalid OTP";
  }

  if (!safeEqual(user.otp, hashOtp(otp))) {
    return "Invalid OTP";
  }

  if (!user.otp_expiry || new Date() > new Date(user.otp_expiry)) {
    return "OTP expired";
  }

  return null;
}

function canUserLogin(user) {
  if (!user.is_verified) {
    return { status: 401, message: "Verify registration OTP first" };
  }

  if (user.status === "pending") {
    return { status: 403, message: "Waiting admin approval" };
  }

  if (user.status === "rejected") {
    return { status: 403, message: "Registration rejected" };
  }

  return null;
}

function validateBasicName(name) {
  return typeof name === "string" && name.trim().length >= 2 && name.trim().length <= 80;
}

exports.registerSenior = async (req, res) => {
  try {
    const {
      name,
      phone,
      age,
      gender,
      ward,
      panchayat,
      house_number,
      house_name,
      pincode,
      health_issues,
      occupation
    } = req.body;

    const normalizedPhone = normalizePhone(phone);
    if (!validateBasicName(name) || !isValidPhone(normalizedPhone)) {
      return res.status(400).json({ message: "Valid name and phone are required" });
    }

    const existingUser = await getUserByPhone(normalizedPhone);
    if (existingUser) {
      return res.status(409).json({ message: "User already exists" });
    }

    const otp = generateOtp();

    await dbQuery(
      `INSERT INTO users (
        name, phone, age, gender, ward, panchayat, house_number, house_name,
        pincode, health_issues, occupation, role, status, otp, otp_expiry, is_verified
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'senior', 'pending', ?, ?, 0)`,
      [
        name.trim(),
        normalizedPhone,
        age || null,
        gender || null,
        ward || null,
        panchayat || null,
        house_number || null,
        house_name || null,
        pincode || null,
        health_issues || null,
        occupation || null,
        hashOtp(otp),
        otpExpiryDate()
      ]
    );

    return sendOtpResponse(res, "Senior registration OTP sent", otp);
  } catch (err) {
    return res.status(500).json({ message: "Failed to register senior" });
  }
};

exports.registerVolunteer = async (req, res) => {
  try {
    const { name, phone, occupation } = req.body;
    const normalizedPhone = normalizePhone(phone);

    if (!validateBasicName(name) || !isValidPhone(normalizedPhone)) {
      return res.status(400).json({ message: "Valid name and phone are required" });
    }

    const existingUser = await getUserByPhone(normalizedPhone);
    if (existingUser) {
      return res.status(409).json({ message: "User already exists" });
    }

    const otp = generateOtp();

    await dbQuery(
      `INSERT INTO users (
        name, phone, occupation, role, status, otp, otp_expiry, is_verified
      ) VALUES (?, ?, ?, 'volunteer', 'pending', ?, ?, 0)`,
      [name.trim(), normalizedPhone, occupation || null, hashOtp(otp), otpExpiryDate()]
    );

    return sendOtpResponse(res, "Volunteer registration OTP sent", otp);
  } catch (err) {
    return res.status(500).json({ message: "Failed to register volunteer" });
  }
};

exports.verifyRegisterOtp = async (req, res) => {
  try {
    const normalizedPhone = normalizePhone(req.body.phone);
    const otp = String(req.body.otp || "").trim();

    if (!isValidPhone(normalizedPhone) || !isValidOtp(otp)) {
      return res.status(400).json({ message: "Valid phone and 6-digit OTP are required" });
    }

    const user = await getUserByPhone(normalizedPhone);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!["senior", "volunteer"].includes(user.role)) {
      return res.status(403).json({ message: "Only senior/volunteer registration is supported" });
    }

    const otpError = validateOtp(user, otp);
    if (otpError) {
      return res.status(400).json({ message: otpError });
    }

    await dbQuery(
      "UPDATE users SET is_verified = 1, otp = NULL, otp_expiry = NULL WHERE phone = ?",
      [normalizedPhone]
    );

    return res.json({ message: "OTP verified. Waiting admin approval." });
  } catch (err) {
    return res.status(500).json({ message: "Failed to verify registration OTP" });
  }
};

exports.userLoginStep1 = async (req, res) => {
  try {
    const normalizedPhone = normalizePhone(req.body.phone);
    if (!isValidPhone(normalizedPhone)) {
      return res.status(400).json({ message: "Valid phone is required" });
    }

    const user = await getUserByPhone(normalizedPhone);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!["senior", "volunteer"].includes(user.role)) {
      return res.status(403).json({ message: "Use admin login for admin accounts" });
    }

    const loginEligibility = canUserLogin(user);
    if (loginEligibility) {
      return res.status(loginEligibility.status).json({ message: loginEligibility.message });
    }

    const otp = generateOtp();
    await setOtp(normalizedPhone, otp);

    return sendOtpResponse(res, "Login OTP sent", otp);
  } catch (err) {
    return res.status(500).json({ message: "Failed to send login OTP" });
  }
};

exports.userLoginStep2 = async (req, res) => {
  try {
    const normalizedPhone = normalizePhone(req.body.phone);
    const otp = String(req.body.otp || "").trim();

    if (!isValidPhone(normalizedPhone) || !isValidOtp(otp)) {
      return res.status(400).json({ message: "Valid phone and 6-digit OTP are required" });
    }

    const user = await getUserByPhone(normalizedPhone);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!["senior", "volunteer"].includes(user.role)) {
      return res.status(403).json({ message: "Use admin login for admin accounts" });
    }

    const loginEligibility = canUserLogin(user);
    if (loginEligibility) {
      return res.status(loginEligibility.status).json({ message: loginEligibility.message });
    }

    const otpError = validateOtp(user, otp);
    if (otpError) {
      return res.status(400).json({ message: otpError });
    }

    const token = createJwt(user);
    await clearOtp(normalizedPhone);

    return res.json({
      message: "Login success",
      token,
      role: user.role,
      name: user.name,
      status: user.status
    });
  } catch (err) {
    return res.status(500).json({ message: "Failed to verify login OTP" });
  }
};

exports.adminLoginStep1 = async (req, res) => {
  try {
    const normalizedPhone = normalizePhone(req.body.phone);
    const password = String(req.body.password || "");

    if (!isValidPhone(normalizedPhone) || password.length < 8 || password.length > 128) {
      return res.status(400).json({ message: "Valid phone and password are required" });
    }

    const user = await getUserByPhone(normalizedPhone);
    if (!user || user.role !== "admin") {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    if (!user.password_hash) {
      return res.status(500).json({ message: "Admin password is not configured" });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const otp = generateOtp();
    await setOtp(normalizedPhone, otp);

    return sendOtpResponse(res, "Admin login OTP sent", otp);
  } catch (err) {
    return res.status(500).json({ message: "Failed to process admin login" });
  }
};

exports.adminLoginStep2 = async (req, res) => {
  try {
    const normalizedPhone = normalizePhone(req.body.phone);
    const otp = String(req.body.otp || "").trim();

    if (!isValidPhone(normalizedPhone) || !isValidOtp(otp)) {
      return res.status(400).json({ message: "Valid phone and 6-digit OTP are required" });
    }

    const user = await getUserByPhone(normalizedPhone);
    if (!user || user.role !== "admin") {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const otpError = validateOtp(user, otp);
    if (otpError) {
      return res.status(400).json({ message: otpError });
    }

    const token = createJwt(user);
    await clearOtp(normalizedPhone);

    return res.json({
      message: "Admin login success",
      token,
      role: user.role,
      name: user.name
    });
  } catch (err) {
    return res.status(500).json({ message: "Failed to verify admin OTP" });
  }
};

// Backward-compatible aliases for existing Flutter calls.
exports.loginOtpStep1 = exports.userLoginStep1;
exports.loginOtpStep2 = exports.userLoginStep2;
