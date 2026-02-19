const db = require("./db");

function runQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, result) => {
      if (err) return reject(err);
      resolve(result);
    });
  });
}

async function ensurePasswordHashColumn() {
  await runQuery(
    `ALTER TABLE users
     ADD COLUMN password_hash VARCHAR(255) NULL AFTER role`
  ).catch((err) => {
    // MySQL duplicate column
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });
}

async function ensureOtpColumnCapacity() {
  await runQuery(
    `ALTER TABLE users
     MODIFY COLUMN otp VARCHAR(128) NULL`
  );
}

async function seedAdminPasswordHashFromEnv() {
  const rawHash = process.env.ADMIN_PASSWORD_HASH;
  if (!rawHash) return;

  const hash = rawHash.trim();
  if (!hash.startsWith("$2")) {
    console.warn("ADMIN_PASSWORD_HASH is present but not a bcrypt hash; skipping admin hash seed.");
    return;
  }

  await runQuery(
    `UPDATE users
     SET password_hash = ?
     WHERE role = 'admin' AND (password_hash IS NULL OR password_hash = '')`,
    [hash]
  );
}

async function runMigrations() {
  await ensureOtpColumnCapacity();
  await ensurePasswordHashColumn();
  await seedAdminPasswordHashFromEnv();
}

module.exports = { runMigrations };
