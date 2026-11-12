import 'package:frontend/modules/model/user/user_model.dart';

enum RegisterResult {
  success,
  missingFields,
  passwordTooShort,
  passwordMismatch,
  emailAlreadyExists,
}

class RegisterController {
  RegisterResult register({
    required String username,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final trimmedUsername = username.trim();
    final trimmedPhoneNumber = phoneNumber.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (trimmedUsername.isEmpty ||
        trimmedPhoneNumber.isEmpty ||
        normalizedEmail.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return RegisterResult.missingFields;
    }

    if (password.length < 8) {
      return RegisterResult.passwordTooShort;
    }

    if (password != confirmPassword) {
      return RegisterResult.passwordMismatch;
    }

    if (users.any((user) => user.email.toLowerCase() == normalizedEmail)) {
      return RegisterResult.emailAlreadyExists;
    }

    users.add(
      UserModel(
        username: trimmedUsername,
        phoneNumber: trimmedPhoneNumber,
        email: normalizedEmail,
        password: password,
        role: 'user',
      ),
    );

    return RegisterResult.success;
  }
}
