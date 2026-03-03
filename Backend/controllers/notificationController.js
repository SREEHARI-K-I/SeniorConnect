const db = require("../config/db");

function dbQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, result) => {
      if (err) return reject(err);
      resolve(result);
    });
  });
}

function normalizePlatform(raw) {
  const platform = String(raw || "").trim().toLowerCase();
  if (platform === "android" || platform === "ios" || platform === "web") {
    return platform;
  }
  return "android";
}

function ensureSupportedUser(req, res) {
  if (!req.user || !["senior", "volunteer", "ambulance", "admin"].includes(req.user.role)) {
    res.status(403).json({ message: "Authorized user access only" });
    return false;
  }
  return true;
}

exports.upsertDeviceToken = async (req, res) => {
  if (!ensureSupportedUser(req, res)) return;

  try {
    const userId = req.user.id;
    const token = String(req.body.token || "").trim();
    const platform = normalizePlatform(req.body.platform);

    if (token.length < 20 || token.length > 255) {
      return res.status(400).json({ message: "Valid device token is required" });
    }

    await dbQuery(
      `INSERT INTO device_tokens (user_id, token, platform)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE
         user_id = VALUES(user_id),
         token = VALUES(token),
         platform = VALUES(platform),
         updated_at = CURRENT_TIMESTAMP`,
      [userId, token, platform]
    );

    return res.json({ message: "Device token saved" });
  } catch (err) {
    return res.status(500).json({ message: "Failed to save device token" });
  }
};

exports.deleteDeviceToken = async (req, res) => {
  if (!ensureSupportedUser(req, res)) return;

  try {
    const userId = req.user.id;
    const token = String(req.body.token || "").trim();
    if (!token) {
      return res.status(400).json({ message: "Token is required" });
    }

    await dbQuery(
      "DELETE FROM device_tokens WHERE user_id = ? AND token = ?",
      [userId, token]
    );

    return res.json({ message: "Device token removed" });
  } catch (err) {
    return res.status(500).json({ message: "Failed to remove device token" });
  }
};
