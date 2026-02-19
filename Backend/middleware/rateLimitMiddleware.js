const stores = new Map();

function createRateLimiter({
  windowMs = 15 * 60 * 1000,
  max = 20,
  keyFn = (req) => req.ip || "unknown",
  message = "Too many requests. Try again later."
} = {}) {
  return (req, res, next) => {
    const key = keyFn(req);
    const now = Date.now();

    if (!stores.has(key)) {
      stores.set(key, []);
    }

    const attempts = stores.get(key).filter((ts) => now - ts < windowMs);
    attempts.push(now);
    stores.set(key, attempts);

    if (attempts.length > max) {
      const retryAfterSeconds = Math.ceil((windowMs - (now - attempts[0])) / 1000);
      res.set("Retry-After", String(Math.max(retryAfterSeconds, 1)));
      return res.status(429).json({ message });
    }

    return next();
  };
}

module.exports = { createRateLimiter };
