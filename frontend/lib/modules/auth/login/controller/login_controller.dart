import 'package:frontend/modules/model/user/user_model.dart';

class LoginController {
  UserModel? login(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();

    for (final user in users) {
      if (user.email.toLowerCase() == normalizedEmail &&
          user.password == password) {
        return user;
      }
    }

    return null;
  }
}
