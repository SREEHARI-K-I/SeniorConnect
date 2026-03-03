const crypto = require("crypto");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const db = require("../config/db");
const { sendOtpSms, isSmsModeEnabled } = require("../services/smsService");

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
  return process.env.NODE_ENV !== "production" && !isSmsModeEnabled();
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
            health_issues,occupation,profile_photo,role,status,otp,otp_expiry,is_verified,password_hash
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

function asOptionalText(value) {
  const text = String(value ?? "").trim();
  return text.length ? text : null;
}

function normalizePlatform(raw) {
  const value = String(raw || "").trim().toLowerCase();
  if (value === "android" || value === "ios" || value === "web") return value;
  return "android";
}

async function deliverOtpOrFail(phone, otp) {
  const smsResult = await sendOtpSms(phone, otp);
  if (!smsResult.ok) {
    const error = new Error(smsResult.error || "Failed to send OTP SMS");
    error.isSms = true;
    throw error;
  }
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

    const normalizedAge = asOptionalText(age);
    const normalizedGender = asOptionalText(gender);
    const normalizedWard = asOptionalText(ward);
    const normalizedPanchayat = asOptionalText(panchayat);
    const normalizedHouseNumber = asOptionalText(house_number);
    const normalizedHouseName = asOptionalText(house_name);
    const normalizedPincode = asOptionalText(pincode);
    const normalizedHealthIssues = asOptionalText(health_issues);
    const normalizedOccupation = asOptionalText(occupation);

    const existingUser = await getUserByPhone(normalizedPhone);
    if (existingUser) {
      if (existingUser.role === "senior" && !existingUser.is_verified) {
        const otp = generateOtp();
        await dbQuery(
          `UPDATE users
           SET name = ?, age = ?, gender = ?, ward = ?, panchayat = ?,
               house_number = ?, house_name = ?, pincode = ?, health_issues = ?,
               occupation = ?, status = 'pending', otp = ?, otp_expiry = ?
           WHERE id = ?`,
          [
            name.trim(),
            normalizedAge || existingUser.age || null,
            normalizedGender || existingUser.gender || null,
            normalizedWard || existingUser.ward || null,
            normalizedPanchayat || existingUser.panchayat || null,
            normalizedHouseNumber || existingUser.house_number || null,
            normalizedHouseName || existingUser.house_name || null,
            normalizedPincode || existingUser.pincode || null,
            normalizedHealthIssues || existingUser.health_issues || null,
            normalizedOccupation || existingUser.occupation || null,
            hashOtp(otp),
            otpExpiryDate(),
            existingUser.id
          ]
        );

        await deliverOtpOrFail(normalizedPhone, otp);
        return sendOtpResponse(res, "Senior registration OTP resent", otp);
      }

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
        normalizedAge,
        normalizedGender,
        normalizedWard,
        normalizedPanchayat,
        normalizedHouseNumber,
        normalizedHouseName,
        normalizedPincode,
        normalizedHealthIssues,
        normalizedOccupation,
        hashOtp(otp),
        otpExpiryDate()
      ]
    );

    await deliverOtpOrFail(normalizedPhone, otp);
    return sendOtpResponse(res, "Senior registration OTP sent", otp);
  } catch (err) {
    if (err.isSms) {
      return res.status(502).json({ message: err.message });
    }
    return res.status(500).json({ message: "Failed to register senior" });
  }
};

exports.registerVolunteer = async (req, res) => {
  try {
    const { name, phone, occupation, profile_photo } = req.body;
    const normalizedPhone = normalizePhone(phone);
    const normalizedProfilePhoto = asOptionalText(profile_photo);

    if (!validateBasicName(name) || !isValidPhone(normalizedPhone)) {
      return res.status(400).json({ message: "Valid name and phone are required" });
    }
    if (normalizedProfilePhoto && normalizedProfilePhoto.length > 1_000_000) {
      return res.status(400).json({ message: "Profile photo is too large" });
    }

    const existingUser = await getUserByPhone(normalizedPhone);
    if (existingUser) {
      if (existingUser.role === "volunteer" && !existingUser.is_verified) {
        const otp = generateOtp();
        await dbQuery(
          `UPDATE users
           SET name = ?, occupation = ?, profile_photo = ?, status = 'pending', otp = ?, otp_expiry = ?
           WHERE id = ?`,
          [
            name.trim(),
            occupation || null,
            normalizedProfilePhoto || existingUser.profile_photo || null,
            hashOtp(otp),
            otpExpiryDate(),
            existingUser.id
          ]
        );

        await deliverOtpOrFail(normalizedPhone, otp);
        return sendOtpResponse(res, "Volunteer registration OTP resent", otp);
      }

      return res.status(409).json({ message: "User already exists" });
    }

    const otp = generateOtp();

    await dbQuery(
      `INSERT INTO users (
        name, phone, occupation, profile_photo, role, status, otp, otp_expiry, is_verified
      ) VALUES (?, ?, ?, ?, 'volunteer', 'pending', ?, ?, 0)`,
      [
        name.trim(),
        normalizedPhone,
        occupation || null,
        normalizedProfilePhoto || null,
        hashOtp(otp),
        otpExpiryDate()
      ]
    );

    await deliverOtpOrFail(normalizedPhone, otp);
    return sendOtpResponse(res, "Volunteer registration OTP sent", otp);
  } catch (err) {
    if (err.isSms) {
      return res.status(502).json({ message: err.message });
    }
    return res.status(500).json({ message: "Failed to register volunteer" });
  }
};

exports.verifyRegisterOtp = async (req, res) => {
  try {
    const normalizedPhone = normalizePhone(req.body.phone);
    const otp = String(req.body.otp || "").trim();
    const deviceToken = String(req.body.device_token || "").trim();
    const platform = normalizePlatform(req.body.platform);

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

    if (deviceToken.length >= 20 && deviceToken.length <= 255) {
      await dbQuery(
        `INSERT INTO device_tokens (user_id, token, platform)
         VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE
           user_id = VALUES(user_id),
           token = VALUES(token),
           platform = VALUES(platform),
           updated_at = CURRENT_TIMESTAMP`,
        [user.id, deviceToken, platform]
      );
    }

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

    if (!["senior", "volunteer", "ambulance"].includes(user.role)) {
      return res.status(403).json({ message: "Use admin login for admin accounts" });
    }

    const loginEligibility = canUserLogin(user);
    if (loginEligibility) {
      return res.status(loginEligibility.status).json({ message: loginEligibility.message });
    }

    const otp = generateOtp();
    await setOtp(normalizedPhone, otp);

    await deliverOtpOrFail(normalizedPhone, otp);
    return sendOtpResponse(res, "Login OTP sent", otp);
  } catch (err) {
    if (err.isSms) {
      return res.status(502).json({ message: err.message });
    }
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

    if (!["senior", "volunteer", "ambulance"].includes(user.role)) {
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
      status: user.status,
      profile_photo: user.profile_photo || null
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

    await deliverOtpOrFail(normalizedPhone, otp);
    return sendOtpResponse(res, "Admin login OTP sent", otp);
  } catch (err) {
    if (err.isSms) {
      return res.status(502).json({ message: err.message });
    }
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
