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

async function ensureVolunteerAvailabilityColumn() {
  await runQuery(
    `ALTER TABLE users
     ADD COLUMN is_available TINYINT(1) NOT NULL DEFAULT 0`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });
}

async function ensureServiceRequestsTable() {
  await runQuery(
    `CREATE TABLE IF NOT EXISTS service_requests (
      id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
      senior_id INT NOT NULL,
      volunteer_id INT NULL,
      category VARCHAR(80) NOT NULL,
      description TEXT NULL,
      ward VARCHAR(30) NULL,
      panchayat VARCHAR(80) NULL,
      house_name VARCHAR(120) NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'open',
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      accepted_at DATETIME NULL,
      completed_at DATETIME NULL,
      INDEX idx_sr_senior (senior_id),
      INDEX idx_sr_volunteer (volunteer_id),
      INDEX idx_sr_status (status),
      CONSTRAINT fk_sr_senior FOREIGN KEY (senior_id) REFERENCES users(id) ON DELETE CASCADE,
      CONSTRAINT fk_sr_volunteer FOREIGN KEY (volunteer_id) REFERENCES users(id) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`
  );
}

async function ensureUserLocationColumns() {
  await runQuery(
    `ALTER TABLE users
     ADD COLUMN current_lat DECIMAL(10,7) NULL`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });

  await runQuery(
    `ALTER TABLE users
     ADD COLUMN current_lng DECIMAL(10,7) NULL`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });

  await runQuery(
    `ALTER TABLE users
     ADD COLUMN current_location_updated_at DATETIME NULL`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });
}

async function ensureEmergencyColumnsOnRequests() {
  await runQuery(
    `ALTER TABLE service_requests
     ADD COLUMN is_emergency TINYINT(1) NOT NULL DEFAULT 0`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });

  await runQuery(
    `ALTER TABLE service_requests
     ADD COLUMN emergency_type VARCHAR(20) NULL`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });

  await runQuery(
    `ALTER TABLE service_requests
     ADD COLUMN location_lat DECIMAL(10,7) NULL`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });

  await runQuery(
    `ALTER TABLE service_requests
     ADD COLUMN location_lng DECIMAL(10,7) NULL`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });

  await runQuery(
    `ALTER TABLE service_requests
     ADD COLUMN completion_otp_hash VARCHAR(128) NULL`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });

  await runQuery(
    `ALTER TABLE service_requests
     ADD COLUMN completion_otp_expiry DATETIME NULL`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });
}

async function ensureDeviceTokensTable() {
  await runQuery(
    `CREATE TABLE IF NOT EXISTS device_tokens (
      id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      token VARCHAR(255) NOT NULL,
      platform VARCHAR(20) NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY uniq_token (token),
      UNIQUE KEY uniq_user_platform (user_id, platform),
      INDEX idx_device_tokens_user (user_id),
      CONSTRAINT fk_device_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`
  );
}

async function ensureDeviceTokenColumnCapacity() {
  await runQuery(
    `ALTER TABLE device_tokens
     MODIFY COLUMN token VARCHAR(255) NOT NULL`
  ).catch((err) => {
    if (err && err.code !== "ER_BAD_FIELD_ERROR") {
      throw err;
    }
  });
}

async function ensureEmergencyDispatchTargetsTable() {
  await runQuery(
    `CREATE TABLE IF NOT EXISTS emergency_dispatch_targets (
      id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
      request_id INT NOT NULL,
      responder_id INT NOT NULL,
      responder_role VARCHAR(20) NOT NULL DEFAULT 'ambulance',
      status VARCHAR(20) NOT NULL DEFAULT 'notified',
      notified_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY uniq_request_responder (request_id, responder_id),
      INDEX idx_edt_responder (responder_id),
      INDEX idx_edt_request (request_id),
      CONSTRAINT fk_edt_request FOREIGN KEY (request_id) REFERENCES service_requests(id) ON DELETE CASCADE,
      CONSTRAINT fk_edt_responder FOREIGN KEY (responder_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`
  );
}

async function ensureProfilePhotoColumn() {
  await runQuery(
    `ALTER TABLE users
     ADD COLUMN profile_photo LONGTEXT NULL`
  ).catch((err) => {
    if (err && err.code !== "ER_DUP_FIELDNAME") {
      throw err;
    }
  });
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

async function ensureAmbulanceSeedUsers() {
  const seedUsers = [
    { name: "City Ambulance 1", phone: "9000010001" },
    { name: "City Ambulance 2", phone: "9000010002" }
  ];

  for (const user of seedUsers) {
    const existing = await runQuery(
      "SELECT id FROM users WHERE phone = ? AND role = 'ambulance' LIMIT 1",
      [user.phone]
    );

    if (existing.length) continue;

    await runQuery(
      `INSERT INTO users (
        name, phone, role, status, is_verified, occupation, is_available
      ) VALUES (?, ?, 'ambulance', 'approved', 1, 'Ambulance Driver', 0)`,
      [user.name, user.phone]
    );
  }
}

async function runMigrations() {
  await ensureOtpColumnCapacity();
  await ensurePasswordHashColumn();
  await ensureVolunteerAvailabilityColumn();
  await ensureServiceRequestsTable();
  await ensureUserLocationColumns();
  await ensureEmergencyColumnsOnRequests();
  await ensureProfilePhotoColumn();
  await ensureEmergencyDispatchTargetsTable();
  await ensureDeviceTokensTable();
  await ensureDeviceTokenColumnCapacity();
  await seedAdminPasswordHashFromEnv();
  await ensureAmbulanceSeedUsers();
}

module.exports = { runMigrations };
