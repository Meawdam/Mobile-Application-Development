const authService = require("./auth_service");

class AuthController {
  async register(req, res, next) {
    try {
      const { username, email, password, role } = req.body;

      if (!username || !email || !password) {
        return res.status(400).json({ message: "Missing required fields" });
      }

      const newUser = await authService.register({
        username,
        email,
        password,
        role,
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
      const { username, password } = req.body;

      if (!username || !password) {
        return res.status(400).json({ message: "Missing required fields" });
      }

      const result = await authService.login({
        username,
        password,
      });

      return res.status(200).json({
        message: "Login successful",
        token: result.token,
        user: result.user
      })
    } catch (error) {
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
