const db = require("../../db_config");

class userRepository {
    async findAll() {
        const [rows] = await db.query(
            "SELECT id, username, role FROM users"
        );
        return rows;
    }

    async findById(id) {
        const [rows] = await db.query(
            "SELECT id, username, role FROM users WHERE id = ?",
            [id]
        );
        return rows[0];
    }
}

module.exports = new userRepository();