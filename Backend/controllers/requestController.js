const db = require("../config/db");
const crypto = require("crypto");
const {
  sendEmergencyPushToVolunteer,
  sendServiceRequestPushToVolunteer,
  sendAmbulanceAlarmCleared,
  sendEmergencyAlarmStopToUser
} = require("../services/pushService");

const ALLOWED_REQUEST_STATUSES = ["open", "accepted", "rejected", "completed", "cancelled"];
const SOS_DISPATCH_LIMIT = Number(process.env.SOS_DISPATCH_LIMIT || 20);
const SOS_MAX_DISTANCE_KM = Number(process.env.SOS_MAX_DISTANCE_KM || 10);
const COMPLETION_OTP_REGEX = /^\d{6}$/;
const COMPLETION_OTP_EXPIRY_MINUTES = 5;

function dbQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, result) => {
      if (err) return reject(err);
      resolve(result);
    });
  });
}

function ensureRole(req, res, role) {
  if (!req.user || req.user.role !== role) {
    res.status(403).json({ message: `${role} access only` });
    return false;
  }
  return true;
}

function ensureResponderRole(req, res) {
  if (!req.user || !["volunteer", "ambulance"].includes(req.user.role)) {
    res.status(403).json({ message: "Responder access only" });
    return false;
  }
  return true;
}

function parseRequestId(raw) {
  const id = Number(raw);
  if (!Number.isInteger(id) || id <= 0) return null;
  return id;
}

function parseCoordinate(raw) {
  const value = Number(raw);
  if (!Number.isFinite(value)) return null;
  return value;
}

function isValidLatitude(lat) {
  return lat >= -90 && lat <= 90;
}

function isValidLongitude(lng) {
  return lng >= -180 && lng <= 180;
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
  return process.env.NODE_ENV !== "production";
}

exports.getAvailableVolunteers = async (req, res) => {
  if (!ensureRole(req, res, "senior")) return;

  try {
    const rows = await dbQuery(
      `SELECT id,name,phone,ward,panchayat,occupation,profile_photo
       FROM users
       WHERE role='volunteer'
         AND status='approved'
         AND is_verified=1
         AND is_available=1
       ORDER BY id DESC`
    );

    return res.json(rows);
  } catch (err) {
    return res.status(500).json({ message: "Failed to fetch available volunteers" });
  }
};

exports.createRequest = async (req, res) => {
  if (!ensureRole(req, res, "senior")) return;

  try {
    const seniorId = req.user.id;
    const category = String(req.body.category || "").trim();
    const description = String(req.body.description || "").trim();
    const preferredVolunteerId = req.body.preferred_volunteer_id
      ? Number(req.body.preferred_volunteer_id)
      : null;

    if (!category || category.length > 80) {
      return res.status(400).json({ message: "Valid category is required" });
    }

    if (preferredVolunteerId === null) {
      return res.status(400).json({ message: "Please select a volunteer" });
    }

    if (!Number.isInteger(preferredVolunteerId) || preferredVolunteerId <= 0) {
      return res.status(400).json({ message: "Invalid preferred volunteer" });
    }

    const seniorRows = await dbQuery(
      "SELECT name,ward,panchayat,house_name FROM users WHERE id = ? AND role='senior' LIMIT 1",
      [seniorId]
    );

    if (!seniorRows.length) {
      return res.status(404).json({ message: "Senior user not found" });
    }

    const volunteerRows = await dbQuery(
      `SELECT id FROM users
       WHERE id = ?
         AND role='volunteer'
         AND status='approved'
         AND is_verified=1`,
      [preferredVolunteerId]
    );

    if (!volunteerRows.length) {
      return res.status(400).json({ message: "Preferred volunteer is not available" });
    }

    const senior = seniorRows[0];
    const result = await dbQuery(
      `INSERT INTO service_requests (
          senior_id, volunteer_id, category, description, ward, panchayat, house_name, status
       ) VALUES (?, ?, ?, ?, ?, ?, ?, 'open')`,
      [
        seniorId,
        preferredVolunteerId,
        category,
        description || null,
        senior.ward || null,
        senior.panchayat || null,
        senior.house_name || null
      ]
    );

    sendServiceRequestPushToVolunteer({
      volunteerId: preferredVolunteerId,
      category,
      requestId: result.insertId,
      seniorName: senior.name || "A senior"
    }).catch(() => {
      // Do not fail request creation if push notification fails.
    });

    return res.status(201).json({
      message: "Service request created",
      request_id: result.insertId
    });
  } catch (err) {
    return res.status(500).json({ message: "Failed to create service request" });
  }
};

exports.createEmergencyRequest = async (req, res) => {
  if (!ensureRole(req, res, "senior")) return;

  try {
    const seniorId = req.user.id;
    const emergencyType = String(req.body.type || "").trim().toLowerCase();
    const latitude = parseCoordinate(req.body.latitude);
    const longitude = parseCoordinate(req.body.longitude);

    if (!["sos", "ambulance"].includes(emergencyType)) {
      return res.status(400).json({ message: "Emergency type must be sos or ambulance" });
    }

    if (latitude === null || longitude === null || !isValidLatitude(latitude) || !isValidLongitude(longitude)) {
      return res.status(400).json({ message: "Valid latitude and longitude are required" });
    }

    const seniorRows = await dbQuery(
      "SELECT ward,panchayat,house_name FROM users WHERE id = ? AND role='senior' LIMIT 1",
      [seniorId]
    );

    if (!seniorRows.length) {
      return res.status(404).json({ message: "Senior user not found" });
    }

    const responderRole = emergencyType === "ambulance" ? "ambulance" : "volunteer";
    const baseLimit = emergencyType === "ambulance" ? 4 : 100;
    const candidateRows = await dbQuery(
      `SELECT id,name,phone,
              (6371 * ACOS(
                COS(RADIANS(?)) * COS(RADIANS(current_lat))
                * COS(RADIANS(current_lng) - RADIANS(?))
                + SIN(RADIANS(?)) * SIN(RADIANS(current_lat))
              )) AS distance_km,
              CASE
                WHEN LOWER(COALESCE(occupation, '')) LIKE '%ambulance%'
                  OR LOWER(COALESCE(occupation, '')) LIKE '%driver%'
                  OR LOWER(COALESCE(occupation, '')) LIKE '%medical%'
                THEN 1 ELSE 0
              END AS ambulance_match
       FROM users
       WHERE role=?
         AND status='approved'
         AND is_verified=1
         AND is_available=1
         AND current_lat IS NOT NULL
         AND current_lng IS NOT NULL
       ORDER BY ambulance_match DESC, distance_km ASC
       LIMIT ?`,
      [latitude, longitude, latitude, responderRole, baseLimit]
    );

    const nearestRows = emergencyType === "ambulance"
      ? candidateRows.slice(0, 4)
      : candidateRows
        .filter((row) => Number(row.distance_km) <= SOS_MAX_DISTANCE_KM)
        .slice(0, SOS_DISPATCH_LIMIT);

    const nearest = nearestRows.length ? nearestRows[0] : null;
    const emergencyLabel = emergencyType === "ambulance" ? "Ambulance Emergency" : "SOS Emergency";

    const senior = seniorRows[0];
    const result = await dbQuery(
      `INSERT INTO service_requests (
          senior_id, volunteer_id, category, description, ward, panchayat, house_name,
          status, is_emergency, emergency_type, location_lat, location_lng
       ) VALUES (?, ?, ?, ?, ?, ?, ?, 'open', 1, ?, ?, ?)`,
      [
        seniorId,
        null,
        emergencyLabel,
        `Emergency alert (${emergencyType}) from mobile`,
        senior.ward || null,
        senior.panchayat || null,
        senior.house_name || null,
        emergencyType,
        latitude,
        longitude
      ]
    );

    if (nearestRows.length) {
      await dbQuery(
        `INSERT INTO emergency_dispatch_targets (request_id, responder_id, responder_role, status)
         VALUES ?`,
        [
          nearestRows.map((row) => [result.insertId, row.id, responderRole, "notified"])
        ]
      );

      await Promise.all(
        nearestRows.map((row) =>
          sendEmergencyPushToVolunteer({
            volunteerId: row.id,
            emergencyType,
            requestId: result.insertId,
            latitude,
            longitude
          }).catch(() => {
            // Do not fail emergency creation if push notification fails.
          })
        )
      );
    }

    return res.status(201).json({
      message: nearest
        ? "Emergency alert sent to nearest responder"
        : "Emergency alert recorded. No nearby active responder found.",
      request_id: result.insertId,
      assigned_volunteer: nearest
        ? {
            id: nearest.id,
            name: nearest.name,
            phone: nearest.phone,
            role: responderRole,
            distance_km: Number(nearest.distance_km || 0).toFixed(2)
          }
        : null,
      notified_ambulances: emergencyType === "ambulance"
        ? nearestRows.map((row) => ({
            id: row.id,
            name: row.name,
            phone: row.phone,
            distance_km: Number(row.distance_km || 0).toFixed(2)
          }))
        : undefined,
      notified_volunteers: emergencyType === "sos"
        ? nearestRows.map((row) => ({
            id: row.id,
            name: row.name,
            phone: row.phone,
            distance_km: Number(row.distance_km || 0).toFixed(2)
          }))
        : undefined
    });
  } catch (err) {
    return res.status(500).json({ message: "Failed to create emergency request" });
  }
};

exports.getMyRequests = async (req, res) => {
  if (!ensureRole(req, res, "senior")) return;

  try {
    const rows = await dbQuery(
      `SELECT sr.id,sr.category,sr.description,sr.status,sr.created_at,
              v.name AS volunteer_name,v.phone AS volunteer_phone
       FROM service_requests sr
       LEFT JOIN users v ON v.id = sr.volunteer_id
       WHERE sr.senior_id = ?
       ORDER BY sr.id DESC`,
      [req.user.id]
    );

    return res.json(rows);
  } catch (err) {
    return res.status(500).json({ message: "Failed to fetch requests" });
  }
};

exports.getVolunteerRequests = async (req, res) => {
  if (!ensureResponderRole(req, res)) return;

  try {
    const isAmbulance = req.user.role === "ambulance";
    let rows;

    if (isAmbulance) {
      rows = await dbQuery(
        `SELECT sr.id,sr.category,sr.description,sr.status,sr.created_at,
                s.name AS senior_name,s.phone AS senior_phone,s.age AS senior_age,
                sr.ward,sr.panchayat,sr.house_name,sr.is_emergency,sr.emergency_type,
                sr.location_lat,sr.location_lng
         FROM service_requests sr
         JOIN users s ON s.id = sr.senior_id
         LEFT JOIN emergency_dispatch_targets edt
           ON edt.request_id = sr.id AND edt.responder_id = ?
         WHERE (
           (sr.status='open' AND sr.is_emergency=1 AND sr.emergency_type='ambulance'
            AND edt.status IN ('notified','accepted'))
           OR (sr.status='accepted' AND sr.volunteer_id = ?)
         )
         ORDER BY sr.is_emergency DESC, sr.id DESC`,
        [req.user.id, req.user.id]
      );
    } else {
      rows = await dbQuery(
        `SELECT sr.id,sr.category,sr.description,sr.status,sr.created_at,
                s.name AS senior_name,s.phone AS senior_phone,s.age AS senior_age,
                sr.ward,sr.panchayat,sr.house_name,sr.is_emergency,sr.emergency_type,
                sr.location_lat,sr.location_lng
         FROM service_requests sr
         JOIN users s ON s.id = sr.senior_id
         LEFT JOIN emergency_dispatch_targets edt
           ON edt.request_id = sr.id AND edt.responder_id = ?
         WHERE (
           (sr.status='open' AND sr.is_emergency=1 AND sr.emergency_type='sos'
            AND edt.status IN ('notified','accepted'))
           OR
           (sr.status='open' AND (sr.is_emergency = 0 OR sr.emergency_type IS NULL)
            AND (sr.volunteer_id IS NULL OR sr.volunteer_id = ?))
           OR (sr.status='accepted' AND sr.volunteer_id = ?)
         )
         ORDER BY sr.is_emergency DESC, sr.id DESC`,
        [req.user.id, req.user.id, req.user.id]
      );
    }

    return res.json(rows);
  } catch (err) {
    return res.status(500).json({ message: "Failed to fetch volunteer requests" });
  }
};

exports.acceptRequest = async (req, res) => {
  if (!ensureResponderRole(req, res)) return;

  try {
    const requestId = parseRequestId(req.params.requestId);
    if (!requestId) {
      return res.status(400).json({ message: "Invalid request id" });
    }

    const roleGuardSql = req.user.role === "ambulance"
      ? ` AND is_emergency = 1 AND emergency_type = 'ambulance'
          AND EXISTS (
            SELECT 1
            FROM emergency_dispatch_targets edt
            WHERE edt.request_id = service_requests.id
              AND edt.responder_id = ?
              AND edt.status IN ('notified','accepted')
          )`
      : ` AND (
            (is_emergency = 1 AND emergency_type = 'sos'
              AND EXISTS (
                SELECT 1
                FROM emergency_dispatch_targets edt
                WHERE edt.request_id = service_requests.id
                  AND edt.responder_id = ?
                  AND edt.status IN ('notified','accepted')
              )
            )
            OR (is_emergency = 0 OR emergency_type IS NULL)
          )`;
    const roleParams = [req.user.id];
    const result = await dbQuery(
      `UPDATE service_requests
       SET volunteer_id = ?, status='accepted', accepted_at = NOW()
       WHERE id = ?
         AND status='open'
         AND (volunteer_id IS NULL OR volunteer_id = ?)
         ${roleGuardSql}`,
      [req.user.id, requestId, req.user.id, ...roleParams]
    );

    if (!result.affectedRows) {
      return res.status(409).json({ message: "Request is no longer available" });
    }

    if (req.user.role === "ambulance") {
      const rows = await dbQuery(
        `SELECT sr.id,sr.is_emergency,sr.emergency_type,u.name
         FROM service_requests sr
         JOIN users u ON u.id = sr.volunteer_id
         WHERE sr.id = ? LIMIT 1`,
        [requestId]
      );

      if (
        rows.length &&
        (rows[0].is_emergency === 1 || rows[0].is_emergency === true) &&
        String(rows[0].emergency_type || "").toLowerCase() === "ambulance"
      ) {
        await dbQuery(
          `UPDATE emergency_dispatch_targets
           SET status = CASE WHEN responder_id = ? THEN 'accepted' ELSE 'closed' END
           WHERE request_id = ?`,
          [req.user.id, requestId]
        );

        sendAmbulanceAlarmCleared({
          requestId,
          acceptedByName: rows[0].name || "Another ambulance"
        }).catch(() => {
          // Do not fail acceptance when push fanout fails.
        });
      }
    } else {
      const rows = await dbQuery(
        `SELECT sr.id,sr.is_emergency,sr.emergency_type,u.name
         FROM service_requests sr
         JOIN users u ON u.id = sr.volunteer_id
         WHERE sr.id = ? LIMIT 1`,
        [requestId]
      );

      if (
        rows.length &&
        (rows[0].is_emergency === 1 || rows[0].is_emergency === true) &&
        String(rows[0].emergency_type || "").toLowerCase() === "sos"
      ) {
        const otherTargets = await dbQuery(
          `SELECT responder_id
           FROM emergency_dispatch_targets
           WHERE request_id = ?
             AND responder_role = 'volunteer'
             AND responder_id <> ?
             AND status IN ('notified','accepted')`,
          [requestId, req.user.id]
        );

        await dbQuery(
          `UPDATE emergency_dispatch_targets
           SET status = CASE WHEN responder_id = ? THEN 'accepted' ELSE 'closed' END
           WHERE request_id = ? AND responder_role = 'volunteer'`,
          [req.user.id, requestId]
        );

        sendEmergencyAlarmStopToUser({
          userId: req.user.id,
          requestId,
          title: "SOS Request Accepted",
          body: "Alarm cleared on your device."
        }).catch(() => {});

        await Promise.all(
          otherTargets.map((row) =>
            sendEmergencyAlarmStopToUser({
              userId: row.responder_id,
              requestId,
              title: "SOS Request Accepted",
              body: `${rows[0].name || "Another volunteer"} accepted the SOS request.`
            }).catch(() => {})
          )
        );
      }
    }

    return res.json({ message: "Request accepted" });
  } catch (err) {
    return res.status(500).json({ message: "Failed to accept request" });
  }
};

exports.rejectRequest = async (req, res) => {
  if (!ensureResponderRole(req, res)) return;

  try {
    const requestId = parseRequestId(req.params.requestId);
    if (!requestId) {
      return res.status(400).json({ message: "Invalid request id" });
    }

    if (req.user.role === "ambulance") {
      const dispatchResult = await dbQuery(
        `UPDATE emergency_dispatch_targets
         SET status = 'rejected'
         WHERE request_id = ? AND responder_id = ? AND status IN ('notified','accepted')`,
        [requestId, req.user.id]
      );

      if (!dispatchResult.affectedRows) {
        return res.status(409).json({ message: "Request is no longer available" });
      }

      const pendingTargets = await dbQuery(
        `SELECT COUNT(*) AS total
         FROM emergency_dispatch_targets
         WHERE request_id = ? AND status IN ('notified','accepted')`,
        [requestId]
      );

      if ((pendingTargets[0]?.total || 0) === 0) {
        await dbQuery(
          `UPDATE service_requests
           SET status='rejected'
           WHERE id = ? AND status='open' AND is_emergency=1 AND emergency_type='ambulance'`,
          [requestId]
        );
      }

      sendEmergencyAlarmStopToUser({
        userId: req.user.id,
        requestId,
        title: "Ambulance Request Rejected",
        body: "Alarm cleared for this request on your device."
      }).catch(() => {
        // Do not fail reject flow if push fails.
      });

      return res.json({ message: "Request rejected for this ambulance" });
    }

    const emergencyRows = await dbQuery(
      `SELECT id
       FROM service_requests
       WHERE id = ? AND status='open' AND is_emergency=1 AND emergency_type='sos'`,
      [requestId]
    );

    if (emergencyRows.length) {
      const dispatchResult = await dbQuery(
        `UPDATE emergency_dispatch_targets
         SET status = 'rejected'
         WHERE request_id = ? AND responder_id = ? AND responder_role = 'volunteer'
           AND status IN ('notified','accepted')`,
        [requestId, req.user.id]
      );

      if (!dispatchResult.affectedRows) {
        return res.status(409).json({ message: "Request is no longer available" });
      }

      const pendingTargets = await dbQuery(
        `SELECT COUNT(*) AS total
         FROM emergency_dispatch_targets
         WHERE request_id = ?
           AND responder_role = 'volunteer'
           AND status IN ('notified','accepted')`,
        [requestId]
      );

      if ((pendingTargets[0]?.total || 0) === 0) {
        await dbQuery(
          `UPDATE service_requests
           SET status='rejected'
           WHERE id = ? AND status='open' AND is_emergency=1 AND emergency_type='sos'`,
          [requestId]
        );
      }

      sendEmergencyAlarmStopToUser({
        userId: req.user.id,
        requestId,
        title: "SOS Request Rejected",
        body: "Alarm cleared for this request on your device."
      }).catch(() => {});

      return res.json({ message: "Request rejected for this volunteer" });
    }

    const result = await dbQuery(
      `UPDATE service_requests
       SET volunteer_id = ?, status='rejected'
       WHERE id = ?
         AND status='open'
         AND (volunteer_id IS NULL OR volunteer_id = ?)
         AND (is_emergency = 0 OR emergency_type <> 'ambulance' OR emergency_type IS NULL)`,
      [req.user.id, requestId, req.user.id]
    );

    if (!result.affectedRows) {
      return res.status(409).json({ message: "Request is no longer available" });
    }

    return res.json({ message: "Request rejected" });
  } catch (err) {
    return res.status(500).json({ message: "Failed to reject request" });
  }
};

exports.generateCompletionOtp = async (req, res) => {
  if (!req.user || req.user.role !== "volunteer") {
    return res.status(403).json({ message: "volunteer access only" });
  }

  try {
    const requestId = parseRequestId(req.params.requestId);
    if (!requestId) {
      return res.status(400).json({ message: "Invalid request id" });
    }

    const rows = await dbQuery(
      `SELECT id
       FROM service_requests
       WHERE id = ?
         AND volunteer_id = ?
         AND status = 'accepted'`,
      [requestId, req.user.id]
    );

    if (!rows.length) {
      return res.status(409).json({ message: "Request must be accepted by you first" });
    }

    const otp = generateOtp();
    const expiry = new Date(Date.now() + COMPLETION_OTP_EXPIRY_MINUTES * 60 * 1000);

    await dbQuery(
      `UPDATE service_requests
       SET completion_otp_hash = ?, completion_otp_expiry = ?
       WHERE id = ?`,
      [hashOtp(otp), expiry, requestId]
    );

    return res.json({
      message: "Completion OTP generated",
      otp: shouldReturnOtpForTesting() ? otp : undefined
    });
  } catch (err) {
    return res.status(500).json({ message: "Failed to generate completion OTP" });
  }
};

exports.completeRequest = async (req, res) => {
  if (!ensureResponderRole(req, res)) return;

  try {
    const requestId = parseRequestId(req.params.requestId);
    if (!requestId) {
      return res.status(400).json({ message: "Invalid request id" });
    }

    const roleGuardSql = req.user.role === "ambulance"
      ? ` AND is_emergency = 1 AND emergency_type = 'ambulance'
          AND EXISTS (
            SELECT 1
            FROM emergency_dispatch_targets edt
            WHERE edt.request_id = service_requests.id
              AND edt.responder_id = ?
              AND edt.status IN ('accepted')
          )`
      : ` AND (
            (is_emergency = 1 AND emergency_type = 'sos'
              AND EXISTS (
                SELECT 1
                FROM emergency_dispatch_targets edt
                WHERE edt.request_id = service_requests.id
                  AND edt.responder_id = ?
                  AND edt.status IN ('accepted')
              )
            )
            OR (is_emergency = 0 OR emergency_type IS NULL)
          )`;
    const roleParams = [req.user.id];

    if (req.user.role === "volunteer") {
      const otp = String(req.body?.completion_otp || "").trim();
      if (!COMPLETION_OTP_REGEX.test(otp)) {
        return res.status(400).json({ message: "Valid 6-digit completion OTP is required" });
      }

      const rows = await dbQuery(
        `SELECT completion_otp_hash, completion_otp_expiry
         FROM service_requests
         WHERE id = ?
           AND volunteer_id = ?
           AND status='accepted'
           ${roleGuardSql}
         LIMIT 1`,
        [requestId, req.user.id, ...roleParams]
      );

      if (!rows.length) {
        return res.status(409).json({ message: "Request cannot be completed" });
      }

      const row = rows[0];
      if (!row.completion_otp_hash) {
        return res.status(400).json({ message: "Generate completion OTP first" });
      }

      if (!safeEqual(row.completion_otp_hash, hashOtp(otp))) {
        return res.status(400).json({ message: "Invalid completion OTP" });
      }

      if (!row.completion_otp_expiry || new Date() > new Date(row.completion_otp_expiry)) {
        return res.status(400).json({ message: "Completion OTP expired" });
      }
    }

    const result = await dbQuery(
      `UPDATE service_requests
       SET status='completed',
           completed_at = NOW(),
           completion_otp_hash = NULL,
           completion_otp_expiry = NULL
       WHERE id = ?
         AND volunteer_id = ?
         AND status='accepted'
         ${roleGuardSql}`,
      [requestId, req.user.id, ...roleParams]
    );

    if (!result.affectedRows) {
      return res.status(409).json({ message: "Request cannot be completed" });
    }

    return res.json({ message: "Request completed" });
  } catch (err) {
    return res.status(500).json({ message: "Failed to complete request" });
  }
};

exports.updateVolunteerAvailability = async (req, res) => {
  if (!ensureResponderRole(req, res)) return;

  try {
    const isAvailable = req.body.is_available === true || req.body.is_available === 1;
    const latitude = req.body.latitude === undefined ? null : parseCoordinate(req.body.latitude);
    const longitude = req.body.longitude === undefined ? null : parseCoordinate(req.body.longitude);

    if (latitude !== null && !isValidLatitude(latitude)) {
      return res.status(400).json({ message: "Invalid latitude" });
    }

    if (longitude !== null && !isValidLongitude(longitude)) {
      return res.status(400).json({ message: "Invalid longitude" });
    }

    await dbQuery(
      `UPDATE users
       SET is_available = ?,
           current_lat = ?,
           current_lng = ?,
           current_location_updated_at = ?
       WHERE id = ? AND role IN ('volunteer','ambulance')`,
      [
        isAvailable ? 1 : 0,
        latitude,
        longitude,
        latitude !== null && longitude !== null ? new Date() : null,
        req.user.id
      ]
    );

    return res.json({ message: "Availability updated", is_available: isAvailable });
  } catch (err) {
    return res.status(500).json({ message: "Failed to update availability" });
  }
};

exports.getVolunteerHistory = async (req, res) => {
  if (!ensureResponderRole(req, res)) return;

  try {
    const rows = await dbQuery(
      `SELECT sr.id,sr.category,sr.description,sr.status,sr.completed_at,sr.created_at,
              s.name AS senior_name,s.ward,s.panchayat,s.house_name
       FROM service_requests sr
       JOIN users s ON s.id = sr.senior_id
       WHERE sr.volunteer_id = ?
         AND sr.status IN ('completed','rejected')
       ORDER BY sr.id DESC`,
      [req.user.id]
    );

    return res.json(rows);
  } catch (err) {
    return res.status(500).json({ message: "Failed to fetch history" });
  }
};

exports.getVolunteerAvailability = async (req, res) => {
  if (!ensureResponderRole(req, res)) return;

  try {
    const rows = await dbQuery(
      "SELECT is_available FROM users WHERE id = ? AND role IN ('volunteer','ambulance') LIMIT 1",
      [req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ message: "Volunteer not found" });
    }

    return res.json({ is_available: rows[0].is_available === 1 });
  } catch (err) {
    return res.status(500).json({ message: "Failed to fetch availability" });
  }
};

exports.getResponderProfile = async (req, res) => {
  if (!ensureResponderRole(req, res)) return;

  try {
    const rows = await dbQuery(
      `SELECT id,name,phone,profile_photo
       FROM users
       WHERE id = ? AND role IN ('volunteer','ambulance')
       LIMIT 1`,
      [req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ message: "User not found" });
    }

    const user = rows[0];
    return res.json({
      id: user.id,
      name: user.name || null,
      phone: user.phone || null,
      profile_photo: user.profile_photo || null
    });
  } catch (err) {
    return res.status(500).json({ message: "Failed to fetch profile" });
  }
};
