const argon2 = require("@node-rs/argon2");
const jwt = require("jsonwebtoken");
const authRepository = require("./auth_repository");

const JWT_SECRET = "PleASeA";

class AuthService {
  async register({ username, email, password }) {
    const existingUsername = await authRepository.findByUsername(username);
    if (existingUsername) {
      const err = new Error("Username is already taken");
      err.status = 400;
      throw err;
    }

    const existingEmail = await authRepository.findByEmail(email);
    if (existingEmail) {
      const err = new Error("Email is already taken");
      err.status = 400;
      throw err;
    }

    const hashedPassword = await argon2.hash(password);

    const userId = await authRepository.createUser({
      username,
      email,
      password: hashedPassword,
      role: "user",
    });

    return { id: userId, username, email, role: "user" };
  }

  async login({ username, password }) {
    const user = await authRepository.findByUsername(username);
    if (!user) {
      const err = new Error("Invalid username or password");
      err.status = 401;
      throw err;
    }

    const isPasswordValid = await argon2.verify(user.password, password);
    if (!isPasswordValid) {
      const err = new Error("Invalid username or password");
      err.status = 401;
      throw err;
    }

    const payload = {
      id: user.id,
      username: user.username,
      role: user.role,
    };

    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: "1d" });

    return {
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
      },
    };
  }
}

module.exports = new AuthService();
