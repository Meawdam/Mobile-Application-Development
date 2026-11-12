import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/model/user/user_model.dart';

/// Persists JWT + current user the same way protected backend routes
/// expect `Authorization: Bearer <token>`.
class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return UserModel.fromJson(decoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
