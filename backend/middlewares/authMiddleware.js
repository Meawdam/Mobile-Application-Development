const jwt = require("jsonwebtoken");

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

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: "Invalid or expired token" });
    }
    req.user = user;
    next();
  });
};

const authenticateToken = (req, res, next) =>
  authenticate(req, res, next, false);

authenticateToken.optional = (req, res, next) =>
  authenticate(req, res, next, true);

module.exports = authenticateToken;
