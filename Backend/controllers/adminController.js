const db = require("../config/db");

/// GET ALL PENDING USERS
exports.getPendingUsers = (req, res) => {
  db.query(
    `SELECT id,name,phone,age,pincode,house_name 
     FROM users 
     WHERE status = 'pending' AND role = 'user'`,
    (err, result) => {
      if (err) return res.status(500).json(err);
      res.json(result);
    }
  );
};


/// APPROVE USER
exports.approveUser = (req, res) => {
  const { userId } = req.params;

  db.query(
    "UPDATE users SET status = 'approved' WHERE id = ?",
    [userId],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "User approved successfully" });
    }
  );
};


/// REJECT USER
exports.rejectUser = (req, res) => {
  const { userId } = req.params;

  db.query(
    "UPDATE users SET status = 'rejected' WHERE id = ?",
    [userId],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "User rejected" });
    }
  );
};
