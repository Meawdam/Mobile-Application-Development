import 'dart:convert';

import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class LoginController {
  Authservice authService = Authservice();

  LoginController({Authservice? service}) {
    if(service == null) {
      // real
      authService = Authservice();
    } else {
      // mocked: unit test
      authService = service;
    }
  }

  Future<String?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return null;
    }

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': normalizedEmail, 'password': password}),
      );
    } on Exception {
      throw Exception('Connection error');
    }

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['user'] is! Map<String, dynamic> ||
        decoded['token'] is! String) {
      throw const FormatException('Invalid login response');
    }

    final user = decoded['user'] as Map<String, dynamic>;
    final role = user['role'];
    if (role is! String) {
      throw const FormatException('Login response is missing the user role');
    }

    await authService.saveToken(decoded['token'] as String);
    return role;
  }
}
