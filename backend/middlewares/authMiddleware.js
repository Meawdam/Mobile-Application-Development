const jwt = require("jsonwebtoken");
const db = require("../db_config");

const JWT_SECRET = "PleASeA";

const authenticate = (req, res, next, optional) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!authHeader && optional) {
    return next();
  }

  if (!token) {
    return res.status(401).json({ message: "Access token required" });
  }

  jwt.verify(token, JWT_SECRET, async (err, user) => {
    if (err) {
      if (optional) {
        return next();
      }
      return res.status(403).json({ message: "Invalid or expired token" });
    }

    try {
      const [rows] = await db.query(
        "SELECT is_suspended, suspension_reason FROM users WHERE id = ?",
        [user.id],
      );
      if (rows.length === 0) {
        return res.status(401).json({ message: "Account no longer exists" });
      }
      if (rows[0].is_suspended) {
        return res.status(403).json({
          message: "Account suspended",
          reason: rows[0].suspension_reason,
        });
      }

      req.user = user;
      next();
    } catch (error) {
      next(error);
    }
  });
};

const authenticateToken = (req, res, next) =>
  authenticate(req, res, next, false);

authenticateToken.optional = (req, res, next) =>
  authenticate(req, res, next, true);

module.exports = authenticateToken;
