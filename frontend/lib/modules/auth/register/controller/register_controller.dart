import 'dart:convert';

import 'package:http/http.dart' as http;

class RegisterController {
  Future<bool> register(
    String username,
    String phoneNumber,
    String email,
    String password,
  ) async {
    final trimmedUsername = username.trim();
    final trimmedPhoneNumber = phoneNumber.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (trimmedUsername.isEmpty ||
        trimmedPhoneNumber.isEmpty ||
        normalizedEmail.isEmpty ||
        password.isEmpty) {
      return false;
    }

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': trimmedUsername,
          'phone_num': trimmedPhoneNumber,
          'email': normalizedEmail,
          'password': password,
        }),
      );
    } on Exception {
      throw Exception('Connection error');
    }

    return response.statusCode == 201;
  }
}
