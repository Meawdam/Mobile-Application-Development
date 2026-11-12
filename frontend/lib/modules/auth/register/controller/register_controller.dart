import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_api.dart';

enum RegisterResult {
  success,
  missingFields,
  passwordTooShort,
  passwordMismatch,
  emailAlreadyExists,
  usernameAlreadyExists,
  failed,
}

class RegisterController {
  RegisterController({AuthApi? authApi}) : _authApi = authApi ?? AuthApi();

  final AuthApi _authApi;

  Future<RegisterResult> register({
    required String username,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
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

    try {
      await _authApi.register(
        username: trimmedUsername,
        email: normalizedEmail,
        password: password,
        phoneNum: trimmedPhoneNumber,
      );
      return RegisterResult.success;
    } on ApiException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('email')) {
        return RegisterResult.emailAlreadyExists;
      }
      if (message.contains('username')) {
        return RegisterResult.usernameAlreadyExists;
      }
      return RegisterResult.failed;
    }
  }
}
