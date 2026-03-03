const https = require("https");

function isSmsModeEnabled() {
  return (process.env.OTP_DELIVERY_MODE || "dev").toLowerCase() === "sms";
}

function providerName() {
  return (process.env.OTP_PROVIDER || "textbelt").toLowerCase();
}

function defaultCountryCode() {
  return process.env.OTP_DEFAULT_COUNTRY_CODE || "+91";
}

function normalizeDestination(phoneDigits) {
  const phone = String(phoneDigits || "").replace(/\D/g, "");
  if (!phone) return "";

  if (phone.length === 10) {
    return `${defaultCountryCode()}${phone}`;
  }

  return phone.startsWith("+") ? phone : `+${phone}`;
}

function otpMessage(otp) {
  const minutes = Number(process.env.OTP_EXPIRY_MINUTES || 5);
  return `Your SeniorConnect OTP is ${otp}. It expires in ${minutes} minutes.`;
}

function postForm(url, payload, authHeader) {
  return new Promise((resolve, reject) => {
    const data = new URLSearchParams(payload).toString();
    const parsedUrl = new URL(url);

    const req = https.request(
      {
        method: "POST",
        hostname: parsedUrl.hostname,
        path: `${parsedUrl.pathname}${parsedUrl.search}`,
        port: parsedUrl.port || 443,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Content-Length": Buffer.byteLength(data),
          ...(authHeader ? { Authorization: authHeader } : {})
        }
      },
      (res) => {
        let body = "";
        res.on("data", (chunk) => {
          body += chunk.toString();
        });
        res.on("end", () => {
          let parsed = {};
          try {
            parsed = body ? JSON.parse(body) : {};
          } catch (e) {
            parsed = { raw: body };
          }
          resolve({ statusCode: res.statusCode || 500, body: parsed });
        });
      }
    );

    req.on("error", reject);
    req.write(data);
    req.end();
  });
}

async function sendViaTextbelt(destination, otp) {
  const apiKey = process.env.TEXTBELT_API_KEY || "textbelt";
  const result = await postForm("https://textbelt.com/text", {
    phone: destination,
    message: otpMessage(otp),
    key: apiKey
  });

  if (result.statusCode >= 400 || result.body.success === false) {
    return {
      ok: false,
      error: result.body.error || `Textbelt failed (${result.statusCode})`
    };
  }

  return { ok: true };
}

async function sendViaTwilio(destination, otp) {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const fromNumber = process.env.TWILIO_FROM_NUMBER;

  if (!accountSid || !authToken || !fromNumber) {
    return {
      ok: false,
      error: "TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_FROM_NUMBER are required"
    };
  }

  const authHeader = `Basic ${Buffer.from(`${accountSid}:${authToken}`).toString("base64")}`;
  const url = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;

  const result = await postForm(
    url,
    {
      To: destination,
      From: fromNumber,
      Body: otpMessage(otp)
    },
    authHeader
  );

  if (result.statusCode >= 400 || result.body.error_code) {
    return {
      ok: false,
      error: result.body.message || `Twilio failed (${result.statusCode})`
    };
  }

  return { ok: true };
}

async function sendOtpSms(phoneDigits, otp) {
  if (!isSmsModeEnabled()) {
    return { ok: true, skipped: true };
  }

  const destination = normalizeDestination(phoneDigits);
  if (!destination) {
    return { ok: false, error: "Invalid destination phone" };
  }

  if (providerName() === "twilio") {
    return sendViaTwilio(destination, otp);
  }

  return sendViaTextbelt(destination, otp);
}

module.exports = {
  sendOtpSms,
  isSmsModeEnabled
};
