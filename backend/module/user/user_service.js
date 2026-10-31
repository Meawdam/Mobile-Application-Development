const userRepository = require("./user_repository");

class UserService {
    async getAllUsers() {
        return await userRepository.findAll();
    }

    async getUserById(id) {
        const user = userRepository.findById(id);
        if(!user) {
            const err = new Error("User not found");
            err.status = 404;
            throw err;
        }
        return user;
    }
}

module.export = new UserService();