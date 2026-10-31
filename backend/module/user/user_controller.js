const userService = require("./user_service");

class UserController {
    async getAllUsers(req, res, next) {
        try {
            const users = await userService.getAllUsers();
            res.status(200).json({data: users});
        } catch (error) {
            next(error);
        }
    }
    async getUserById(req, res, next) {
        try {
            const user = await userService.getUserById(req.params.id);
            res.status(200).json({data: user});
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new UserController();