const db = require("../../db_config");

class AuthRepository {
  async findByUsername(username) {
    const [rows] = await db.query("SELECT * FROM users WHERE username = ?", [
      username,
    ]);
    return rows[0];
  }

  async findByEmail(email) {
    const [rows] = await db.query("SELECT * FROM users WHERE email = ?", [
      email,
    ]);
    return rows[0];
  }

  async createUser({ username, email, password, role = "user" }) {
    const [result] = await db.query(
      "INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, ?)",
      [username, email, password, role],
    );
    return result.insertId;
  }
}

module.exports = new AuthRepository();
