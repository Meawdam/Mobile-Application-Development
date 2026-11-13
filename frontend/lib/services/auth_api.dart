import 'package:frontend/model/user/user_model.dart';

import 'api_client.dart';
import 'auth_session.dart';

class AuthLoginResult {
  final String token;
  final UserModel user;

  const AuthLoginResult({required this.token, required this.user});
}

/// Auth endpoints under `/api/auth` (see `backend/module/auth`).
class AuthApi {
  AuthApi({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/login',
      auth: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    final token = response['token']?.toString();
    final userJson = response['user'];
    if (token == null || token.isEmpty || userJson is! Map<String, dynamic>) {
      throw const ApiException(500, 'Invalid login response from server');
    }

    final user = UserModel.fromJson(userJson);
    await _session.saveSession(token: token, user: user);
    return AuthLoginResult(token: token, user: user);
  }

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String phoneNum,
  }) async {
    final response = await _client.post(
      '/api/auth/register',
      auth: false,
      body: {
        'username': username,
        'email': email,
        'password': password,
        'phone_num': phoneNum,
      },
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(500, 'Invalid register response from server');
    }
    return UserModel.fromJson(data);
  }

  Future<void> logout() => _session.clear();
}
