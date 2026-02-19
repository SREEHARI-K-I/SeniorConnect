const db = require("../config/db");

exports.isAdmin = (req, res, next) => {
  const userId = req.user.id;

  db.query("SELECT role FROM users WHERE id = ?", [userId], (err, result) => {
    if (err) return res.status(500).json(err);

    if (result.length === 0)
      return res.status(404).json({ message: "User not found" });

    if (result[0].role !== "admin")
      return res.status(403).json({ message: "Admin access only" });

    next();
  });
};
