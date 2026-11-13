import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/login/controller/login_controller.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeAuthService extends Authservice {
  String? savedToken;

  @override
  Future<void> saveToken(String jwt) async {
    savedToken = jwt;
  }
}

void main() {
  test('returns the user role and saves the token', () async {
    final controller = LoginController();
    final authService = _FakeAuthService();
    controller.authService = authService;

    final role = await http.runWithClient(
      () => controller.login('user@example.com', 'password123'),
      () => MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        expect(request.method, 'POST');
        return http.Response(
          jsonEncode({
            'token': 'test-token',
            'user': {'role': 'user'},
          }),
          200,
        );
      }),
    );

    expect(role, 'user');
    expect(authService.savedToken, 'test-token');
  });

  test('returns the admin role', () async {
    final controller = LoginController();
    controller.authService = _FakeAuthService();

    final role = await http.runWithClient(
      () => controller.login('admin@example.com', 'password123'),
      () => MockClient(
        (_) async => http.Response(
          jsonEncode({
            'token': 'admin-token',
            'user': {'role': 'admin'},
          }),
          200,
        ),
      ),
    );

    expect(role, 'admin');
  });

  test('normalizes email before sending the request', () async {
    final controller = LoginController();
    controller.authService = _FakeAuthService();

    final role = await http.runWithClient(
      () => controller.login('  USER@EXAMPLE.COM  ', 'password123'),
      () => MockClient((request) async {
        expect(jsonDecode(request.body), {
          'email': 'user@example.com',
          'password': 'password123',
        });
        return http.Response(
          jsonEncode({
            'token': 'test-token',
            'user': {'role': 'user'},
          }),
          200,
        );
      }),
    );

    expect(role, 'user');
  });

  test('returns null when the server rejects the credentials', () async {
    final controller = LoginController();

    final role = await http.runWithClient(
      () => controller.login('user@example.com', 'wrong-password'),
      () => MockClient(
        (_) async => http.Response('Invalid email or password', 401),
      ),
    );

    expect(role, isNull);
  });

  test('does not send a request for empty credentials', () async {
    final controller = LoginController();

    final results = await http.runWithClient(
      () async => [
        await controller.login('  ', 'password123'),
        await controller.login('user@example.com', ''),
      ],
      () => MockClient((_) async => throw StateError('unexpected request')),
    );

    expect(results, [isNull, isNull]);
  });
}
