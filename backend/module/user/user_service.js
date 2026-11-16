const userRepository = require("./user_repository");

class UserService {
    async getAllUsers() {
        return await userRepository.findAll();
    }

    async getUserById(id) {
        const user = await userRepository.findById(id);
        if(!user) {
            const err = new Error("User not found");
            err.status = 404;
            throw err;
        }
        return user;
    }

    async setSuspension(id, actorId, { is_suspended, reason }) {
        const userId = Number(id);
        if (!Number.isSafeInteger(userId) || userId <= 0) {
            const err = new Error("User ID must be a positive integer");
            err.status = 400;
            throw err;
        }
        if (typeof is_suspended !== "boolean") {
            const err = new Error("is_suspended must be a boolean");
            err.status = 400;
            throw err;
        }

        let normalizedReason = null;
        if (is_suspended) {
            if (typeof reason !== "string" || !reason.trim()) {
                const err = new Error("A reason is required to suspend an account");
                err.status = 400;
                throw err;
            }
            normalizedReason = reason.trim();
            if (normalizedReason.length > 500) {
                const err = new Error("Suspension reason must not exceed 500 characters");
                err.status = 400;
                throw err;
            }
        }

        const result = await userRepository.setSuspension(
            userId,
            actorId,
            is_suspended,
            normalizedReason,
        );
        if (!result) {
            const err = new Error("User not found");
            err.status = 404;
            throw err;
        }
        return result;
    }

    async getUserActivities(id, { category, limit = 50, offset = 0 } = {}) {
        const userId = Number(id);
        if (!Number.isSafeInteger(userId) || userId <= 0) {
            const err = new Error("User ID must be a positive integer");
            err.status = 400;
            throw err;
        }
        if (category && !["rental", "finance", "admin"].includes(category)) {
            const err = new Error("category must be rental, finance, or admin");
            err.status = 400;
            throw err;
        }
        const parsedLimit = Number(limit);
        const parsedOffset = Number(offset);
        if (
            !Number.isSafeInteger(parsedLimit) ||
            parsedLimit < 1 ||
            parsedLimit > 100 ||
            !Number.isSafeInteger(parsedOffset) ||
            parsedOffset < 0
        ) {
            const err = new Error("limit must be 1-100 and offset must be non-negative");
            err.status = 400;
            throw err;
        }

        await this.getUserById(userId);
        return userRepository.findActivities(
            userId,
            category,
            parsedLimit,
            parsedOffset,
        );
    }
}

module.exports = new UserService();