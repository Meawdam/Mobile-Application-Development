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
    async setSuspension(req, res, next) {
        try {
            const result = await userService.setSuspension(
                req.params.id,
                req.user.id,
                req.body,
            );
            res.status(200).json({
                message: result.is_suspended
                    ? "User account suspended"
                    : "User account reactivated",
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }
    async getUserActivities(req, res, next) {
        try {
            const activities = await userService.getUserActivities(
                req.params.id,
                req.query,
            );
            res.status(200).json({ data: activities });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new UserController();