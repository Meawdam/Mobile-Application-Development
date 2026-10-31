const userService = require("./user_controller");

class UserController {
    async getAllUser(req, res, next) {
        try {
            const users = await userService.getAllUser();
            res.status(200).json({data: users});
        } catch (error) {
            next(error);
        }
    }
    async getUserById(req, res, next) {
        try {
            const user = await userService.getUserById(get.params.id);
            res.status(200).json({data: user});
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new UsersController();