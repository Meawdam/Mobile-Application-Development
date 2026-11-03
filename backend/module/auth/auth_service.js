const argon2 = require("@node-rs/argon2");
const jwt = require("jsonwebtoken");
const authRepository = require("./auth_repository");

const JWT_SECRET = "PleASeA";

class AuthService {
  async register({ username, email, password, phone_num }) {
    email = email.trim().toLowerCase();
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
      phone_num,
      role: "user",
    });

    return { id: userId, username, email, phone_num, role: "user" };
  }

  async login({ email, password }) {
    const user = await authRepository.findByEmail(email.trim().toLowerCase());
    if (!user) {
      const err = new Error("Invalid email or password");
      err.status = 401;
      throw err;
    }

    const isPasswordValid = await argon2.verify(user.password, password);
    if (!isPasswordValid) {
      const err = new Error("Invalid email or password");
      err.status = 401;
      throw err;
    }

    const payload = {
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
    };

    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: "1d" });

    return {
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        phone_num: user.phone_num,
        role: user.role,
      },
    };
  }
}

module.exports = new AuthService();
