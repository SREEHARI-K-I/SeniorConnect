const db = require("../config/db");

function dbQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, result) => {
      if (err) return reject(err);
      resolve(result);
    });
  });
}

function parseUserId(rawUserId) {
  const userId = Number(rawUserId);
  if (!Number.isInteger(userId) || userId <= 0) return null;
  return userId;
}

// GET ALL PENDING SENIORS
exports.getPendingSeniors = async (req, res) => {
  try {
    const result = await dbQuery(
      `SELECT id,name,phone,age,gender,ward,panchayat,pincode,house_name,occupation
       FROM users
       WHERE status = 'pending' AND role = 'senior'
       ORDER BY id DESC`
    );
    res.json(result);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch pending seniors" });
  }
};

// GET ALL PENDING VOLUNTEERS
exports.getPendingVolunteers = async (req, res) => {
  try {
    const result = await dbQuery(
      `SELECT id,name,phone,age,gender,ward,panchayat,occupation
       FROM users
       WHERE status = 'pending' AND role = 'volunteer'
       ORDER BY id DESC`
    );
    res.json(result);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch pending volunteers" });
  }
};

// GET ALL VOLUNTEERS
exports.getAllVolunteers = async (req, res) => {
  try {
    const result = await dbQuery(
      `SELECT id,name,phone,age,gender,ward,panchayat,occupation,status,is_verified
       FROM users
       WHERE role = 'volunteer'
       ORDER BY id DESC`
    );
    res.json(result);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch volunteers" });
  }
};

// APPROVE USER (Senior OR Volunteer)
exports.approveUser = async (req, res) => {
  try {
    const userId = parseUserId(req.params.userId);
    if (!userId) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const result = await dbQuery(
      "UPDATE users SET status = 'approved' WHERE id = ? AND role IN ('senior','volunteer')",
      [userId]
    );

    if (!result.affectedRows) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.json({ message: "User approved successfully" });
  } catch (err) {
    return res.status(500).json({ message: "Failed to approve user" });
  }
};

// REJECT USER
exports.rejectUser = async (req, res) => {
  try {
    const userId = parseUserId(req.params.userId);
    if (!userId) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const result = await dbQuery(
      "UPDATE users SET status = 'rejected' WHERE id = ? AND role IN ('senior','volunteer')",
      [userId]
    );

    if (!result.affectedRows) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.json({ message: "User rejected successfully" });
  } catch (err) {
    return res.status(500).json({ message: "Failed to reject user" });
  }
};

// ADMIN DASHBOARD STATS
exports.getAdminStats = async (req, res) => {
  try {
    const result = await dbQuery(
      `SELECT
        COUNT(*) AS total_users,
        SUM(role='senior') AS seniors,
        SUM(role='volunteer') AS volunteers,
        SUM(status='pending') AS pending_requests
       FROM users`
    );

    return res.json(result[0] || {});
  } catch (err) {
    return res.status(500).json({ message: "Failed to fetch admin stats" });
  }
};
