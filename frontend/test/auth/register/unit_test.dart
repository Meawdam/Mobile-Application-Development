import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/register/controller/register_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('1. Correct register should return true', () async {
    final registerController = RegisterController();
    final result = await http.runWithClient(
      () => registerController.register(
        'Test User',
        '0800000003',
        'user@example.com',
        '12345678',
      ),
      () => MockClient((request) async {
        expect(request.url.path, '/api/auth/register');
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'username': 'Test User',
          'phone_num': '0800000003',
          'email': 'user@example.com',
          'password': '12345678',
        });
        return http.Response('', 201);
      }),
    );

    expect(result, isTrue);
  });

  test('2. Missing required register data should return false', () async {
    final registerController = RegisterController();
    final result = await http.runWithClient(
      () => registerController.register(
        'Test User',
        '0800000003',
        '',
        '12345678',
      ),
      () => MockClient((_) async => throw StateError('unexpected request')),
    );

    expect(result, isFalse);
  });
}
