const authService = require("./auth_service");

class AuthController {
  async register(req, res, next) {
    try {
      const { username, email, password, phone_num } = req.body;

      if (
        typeof username !== "string" ||
        !username.trim() ||
        typeof email !== "string" ||
        !email.trim() ||
        typeof password !== "string" ||
        !password ||
        typeof phone_num !== "string" ||
        !phone_num.trim() ||
        phone_num.trim().length > 10
      ) {
        return res.status(400).json({ message: "Missing required fields" });
      }

      const newUser = await authService.register({
        username: username.trim(),
        email: email.trim(),
        password,
        phone_num: phone_num.trim(),
      });

      return res.status(201).json({
        message: "User registered successfully",
        data: newUser,
      });
    } catch (error) {
      next(error);
    }
  }

  async login(req, res, next) {
    try {
      const { email, password } = req.body;

      if (
        typeof email !== "string" ||
        !email.trim() ||
        typeof password !== "string" ||
        !password
      ) {
        return res.status(400).json({ message: "Missing required fields" });
      }

      const result = await authService.login({
        email: email.trim(),
        password,
      });

      return res.status(200).json({
        message: "Login successful",
        token: result.token,
        user: result.user
      })
    } catch (error) {
      if (error.status === 403 && error.reason) {
        return res.status(403).json({
          message: error.message,
          reason: error.reason,
        });
      }
      next(error);
    }
  }

  async getProfile(req, res, next) {
    try {
        return res.status(200).json({
            user: req.user
        })
    } catch (error) {
        next(error);
    }
  }

}

module.exports = new AuthController();
