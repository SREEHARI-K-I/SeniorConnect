const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const db = require("../config/db");

let firebaseReady = false;
let firebaseInitAttempted = false;

function dbQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, result) => {
      if (err) return reject(err);
      resolve(result);
    });
  });
}

function initFirebaseIfPossible() {
  if (firebaseInitAttempted) return firebaseReady;
  firebaseInitAttempted = true;

  try {
    const servicePathRaw = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "";
    if (!servicePathRaw) {
      console.warn("FCM disabled: FIREBASE_SERVICE_ACCOUNT_PATH is not configured.");
      return false;
    }

    const fullPath = path.isAbsolute(servicePathRaw)
      ? servicePathRaw
      : path.resolve(process.cwd(), servicePathRaw);

    if (!fs.existsSync(fullPath)) {
      console.warn("FCM disabled: Firebase service account file not found.");
      return false;
    }

    const serviceAccount = JSON.parse(fs.readFileSync(fullPath, "utf8"));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });

    firebaseReady = true;
    return true;
  } catch (err) {
    console.warn("FCM disabled: failed to initialize firebase-admin.");
    return false;
  }
}

async function getVolunteerTokens(volunteerId) {
  const rows = await dbQuery(
    `SELECT token
     FROM device_tokens
     WHERE user_id = ?`,
    [volunteerId]
  );

  return rows
    .map((r) => String(r.token || "").trim())
    .filter(Boolean);
}

async function getUserTokens(userId) {
  const rows = await dbQuery(
    `SELECT token
     FROM device_tokens
     WHERE user_id = ?`,
    [userId]
  );

  return rows
    .map((r) => String(r.token || "").trim())
    .filter(Boolean);
}

async function getRoleTokens(role) {
  const rows = await dbQuery(
    `SELECT dt.token
     FROM device_tokens dt
     JOIN users u ON u.id = dt.user_id
     WHERE u.role = ?`,
    [role]
  );

  return rows
    .map((r) => String(r.token || "").trim())
    .filter(Boolean);
}

async function sendEmergencyPushToVolunteer({
  volunteerId,
  emergencyType,
  requestId,
  latitude,
  longitude
}) {
  if (!volunteerId) return { ok: false, reason: "missing-volunteer-id" };
  if (!initFirebaseIfPossible()) return { ok: false, reason: "fcm-not-configured" };

  const tokens = await getVolunteerTokens(volunteerId);
  if (!tokens.length) return { ok: false, reason: "no-device-token" };

  const title = emergencyType === "ambulance" ? "Ambulance Emergency" : "SOS Emergency";
  const body = emergencyType === "ambulance"
    ? "A senior requested emergency medical help near you."
    : "A senior sent an SOS alert near you.";
  const shouldAlarm = emergencyType === "sos" || emergencyType === "ambulance";

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    android: {
      priority: "high",
      ttl: 60 * 1000
    },
    data: {
      type: "emergency",
      emergency_type: String(emergencyType || ""),
      alarm: shouldAlarm ? "true" : "false",
      request_id: String(requestId || ""),
      latitude: String(latitude ?? ""),
      longitude: String(longitude ?? ""),
      title,
      body
    }
  });

  return {
    ok: true,
    successCount: response.successCount,
    failureCount: response.failureCount
  };
}

async function sendAmbulanceAlarmCleared({
  requestId,
  acceptedByName
}) {
  if (!initFirebaseIfPossible()) return { ok: false, reason: "fcm-not-configured" };
  const tokens = await getRoleTokens("ambulance");
  if (!tokens.length) return { ok: false, reason: "no-device-token" };

  const title = "Ambulance Request Accepted";
  const body = `${acceptedByName || "Another ambulance"} accepted the emergency request.`;

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    android: {
      priority: "high",
      ttl: 2 * 60 * 1000
    },
    data: {
      type: "emergency_alarm_stop",
      alarm: "false",
      request_id: String(requestId || ""),
      title,
      body
    }
  });

  return {
    ok: true,
    successCount: response.successCount,
    failureCount: response.failureCount
  };
}

async function sendEmergencyAlarmStopToUser({
  userId,
  requestId,
  title,
  body
}) {
  if (!userId) return { ok: false, reason: "missing-user-id" };
  if (!initFirebaseIfPossible()) return { ok: false, reason: "fcm-not-configured" };

  const tokens = await getUserTokens(userId);
  if (!tokens.length) return { ok: false, reason: "no-device-token" };

  const pushTitle = title || "Emergency Alert Updated";
  const pushBody = body || "Alarm cleared for this request.";

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    android: {
      priority: "high",
      ttl: 2 * 60 * 1000
    },
    data: {
      type: "emergency_alarm_stop",
      alarm: "false",
      request_id: String(requestId || ""),
      title: pushTitle,
      body: pushBody
    }
  });

  return {
    ok: true,
    successCount: response.successCount,
    failureCount: response.failureCount
  };
}

async function sendServiceRequestPushToVolunteer({
  volunteerId,
  category,
  requestId,
  seniorName
}) {
  if (!volunteerId) return { ok: false, reason: "missing-volunteer-id" };
  if (!initFirebaseIfPossible()) return { ok: false, reason: "fcm-not-configured" };

  const tokens = await getVolunteerTokens(volunteerId);
  if (!tokens.length) return { ok: false, reason: "no-device-token" };

  const title = "New Service Request";
  const body = `${seniorName || "A senior"} requested ${category || "assistance"}.`;

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    android: {
      priority: "high",
      ttl: 60 * 1000,
      notification: {
        channelId: "service_requests",
        sound: "default",
        priority: "high",
        defaultSound: true,
        defaultVibrateTimings: true,
        visibility: "public"
      }
    },
    data: {
      type: "service_request",
      alarm: "false",
      request_id: String(requestId || ""),
      category: String(category || ""),
      title,
      body
    }
  });

  return {
    ok: true,
    successCount: response.successCount,
    failureCount: response.failureCount
  };
}

async function sendAccountStatusPushToUser({
  userId,
  userRole,
  status
}) {
  if (!userId) return { ok: false, reason: "missing-user-id" };
  if (!initFirebaseIfPossible()) return { ok: false, reason: "fcm-not-configured" };

  const tokens = await getUserTokens(userId);
  if (!tokens.length) return { ok: false, reason: "no-device-token" };

  const normalizedStatus = String(status || "").toLowerCase();
  const approved = normalizedStatus === "approved";
  const title = approved ? "Account Approved" : "Account Update";
  const roleLabel = String(userRole || "account");
  const body = approved
    ? `Your ${roleLabel} account has been approved by admin. You can now login.`
    : `Your ${roleLabel} account status is ${normalizedStatus || "updated"}.`;

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    android: {
      priority: "high",
      ttl: 5 * 60 * 1000,
      notification: {
        channelId: "service_requests",
        sound: "default",
        priority: "high",
        defaultSound: true,
        defaultVibrateTimings: true,
        visibility: "public"
      }
    },
    data: {
      type: "account_status",
      status: normalizedStatus,
      role: roleLabel,
      alarm: "false",
      title,
      body
    }
  });

  return {
    ok: true,
    successCount: response.successCount,
    failureCount: response.failureCount
  };
}

module.exports = {
  sendEmergencyPushToVolunteer,
  sendServiceRequestPushToVolunteer,
  sendAccountStatusPushToUser,
  sendAmbulanceAlarmCleared,
  sendEmergencyAlarmStopToUser
};
