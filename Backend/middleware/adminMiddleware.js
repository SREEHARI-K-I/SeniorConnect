const db = require("../config/db");

exports.isAdmin = (req, res, next) => {
  const userId = req.user.id;

  db.query("SELECT role, status, is_verified FROM users WHERE id = ?", [userId], (err, result) => {
    if (err) return res.status(500).json({ message: "Failed to authorize admin" });

    if (result.length === 0)
      return res.status(404).json({ message: "User not found" });

    if (result[0].role !== "admin")
      return res.status(403).json({ message: "Admin access only" });

    if (!result[0].is_verified || result[0].status !== "approved")
      return res.status(403).json({ message: "Admin account is not active" });

    next();
  });
};
