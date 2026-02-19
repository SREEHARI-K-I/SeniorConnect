require("dotenv").config();

const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const adminRoutes = require("./routes/adminRoutes");
const { runMigrations } = require("./config/migrations");

if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 24) {
  throw new Error("JWT_SECRET is missing or too short. Use at least 24 characters.");
}

const app = express();

const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS || "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

app.disable("x-powered-by");
app.set("trust proxy", 1);

app.use((req, res, next) => {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader("Permissions-Policy", "geolocation=(), microphone=(), camera=()")
  ;
  next();
});

app.use(cors({
  origin(origin, callback) {
    // Allow mobile apps / curl with no Origin header.
    if (!origin) return callback(null, true);

    if (!allowedOrigins.length || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    return callback(new Error("CORS origin blocked"));
  }
}));

app.use(express.json({ limit: "32kb" }));

app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);

app.get("/", (req, res) => {
  res.send("Senior Connect Backend Running");
});

app.use((err, req, res, next) => {
  if (err && err.message === "CORS origin blocked") {
    return res.status(403).json({ message: "CORS blocked for this origin" });
  }

  return res.status(500).json({ message: "Unexpected server error" });
});

const port = Number(process.env.PORT || 3000);

runMigrations()
  .then(() => {
    app.listen(port, () => {
      console.log(`Server running on port ${port}`);
    });
  })
  .catch((err) => {
    console.error("Startup migration failed:", err.message);
    process.exit(1);
  });
