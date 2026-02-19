const db = require("../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");


// ================= REGISTER =================
exports.register = async (req, res) => {
  try {
    const { name, phone, email, password, age, pincode, house_name } = req.body;

    if (!name || !phone || !password) {
      return res.status(400).json({ message: "Required fields missing" });
    }

    db.query("SELECT * FROM users WHERE phone = ?", [phone], async (err, result) => {
      if (err) return res.status(500).json({ error: err.message });

      if (result.length > 0) {
        return res.status(400).json({ message: "User already exists" });
      }

      const hashedPassword = await bcrypt.hash(password, 10);
      const otp = Math.floor(100000 + Math.random() * 900000).toString();

      db.query(
        `INSERT INTO users 
        (name, phone, email, password, age, pincode, house_name, otp, is_verified, status, role)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, FALSE, 'pending','user')`,
        [name, phone, email, hashedPassword, age, pincode, house_name, otp],
        (err) => {
          if (err) return res.status(500).json({ error: err.message });

          res.json({
            message: "Registered successfully. Verify OTP.",
            otp: otp
          });
        }
      );
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};


// ================= VERIFY OTP =================
exports.verifyOtp = (req, res) => {
  const { phone, otp } = req.body;

  if (!phone || !otp) {
    return res.status(400).json({ message: "Phone and OTP required" });
  }

  db.query("SELECT * FROM users WHERE phone = ?", [phone], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });

    if (result.length === 0) {
      return res.status(400).json({ message: "User not found" });
    }

    const user = result[0];

    if (user.otp !== otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    db.query(
      "UPDATE users SET is_verified = TRUE, otp = NULL WHERE phone = ?",
      [phone],
      (err) => {
        if (err) return res.status(500).json({ error: err.message });

        res.json({
          message: "OTP verified successfully. Waiting for admin approval."
        });
      }
    );
  });
};


/// ================= LOGIN STEP 1 =================
// Check password and SEND OTP
exports.login = (req, res) => {
  const { phone, password } = req.body;

  db.query("SELECT * FROM users WHERE phone = ?", [phone], async (err, result) => {
    if (err) return res.status(500).json(err);
    if (result.length === 0)
      return res.status(404).json({ message: "User not found" });

    const user = result[0];

    // Must be registered & approved first
    // 🔴 Check registration OTP verified
    if (!user.is_verified)
    return res.status(401).json({ message: "Please verify OTP first" });

    // 🔴 Check admin approval status
    if (user.status === "pending")
    return res.status(403).json({ message: "Waiting for admin approval" });

    if (user.status === "rejected")
    return res.status(403).json({ message: "Admin rejected your request" });


    const match = await bcrypt.compare(password, user.password);
    if (!match)
      return res.status(401).json({ message: "Invalid password" });

    // 🔥 Generate LOGIN OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    db.query(
      "UPDATE users SET otp = ?, otp_expiry = ? WHERE phone = ?",
      [otp, expiry, phone],
      () => {
        res.json({
          message: "Password correct. Enter OTP to login.",
          otp: otp // testing only
        });
      }
    );
  });
};
// ================= LOGIN STEP 2 =================
// Verify OTP and GIVE TOKEN
exports.loginVerifyOtp = (req, res) => {
  const { phone, otp } = req.body;

  db.query("SELECT * FROM users WHERE phone = ?", [phone], (err, result) => {
    if (err) return res.status(500).json(err);
    if (result.length === 0)
      return res.status(404).json({ message: "User not found" });

    const user = result[0];

    if (user.otp !== otp)
      return res.status(400).json({ message: "Invalid OTP" });

    if (new Date() > user.otp_expiry)
      return res.status(400).json({ message: "OTP expired" });

    // Clear OTP
    db.query("UPDATE users SET otp = NULL WHERE phone = ?", [phone]);

    // 🎟 Create JWT
    const token = jwt.sign(
      { id: user.id, phone: user.phone },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.json({
      message: "Login successful",
      token,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone
      }
    });
  });
};

