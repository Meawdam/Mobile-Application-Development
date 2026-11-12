import 'package:frontend/model/user/user_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_api.dart';

class LoginController {
  LoginController({AuthApi? authApi}) : _authApi = authApi ?? AuthApi();

  final AuthApi _authApi;

  Future<UserModel?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return null;
    }

    try {
      final result = await _authApi.login(
        email: normalizedEmail,
        password: password,
      );
      return result.user;
    } on ApiException {
      return null;
    }
  }
}
