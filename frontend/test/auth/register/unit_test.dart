import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/register/controller/register_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sends registration fields to the backend', () async {
    final success = await http.runWithClient(
      () => RegisterController().register(
        ' Test User ',
        ' 0800000003 ',
        ' NEW@EXAMPLE.COM ',
        'newuser123',
      ),
      () => MockClient((request) async {
        expect(request.url.path, '/api/auth/register');
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'username': 'Test User',
          'phone_num': '0800000003',
          'email': 'new@example.com',
          'password': 'newuser123',
        });
        return http.Response('', 201);
      }),
    );

    expect(success, isTrue);
  });

  test('does not send a request when a required field is empty', () async {
    final controller = RegisterController();
    final results = await http.runWithClient(
      () async => [
        await controller.register(
          '',
          '0800000003',
          'user@example.com',
          'password123',
        ),
        await controller.register(
          'User',
          '',
          'user@example.com',
          'password123',
        ),
        await controller.register('User', '0800000003', ' ', 'password123'),
        await controller.register('User', '0800000003', 'user@example.com', ''),
      ],
      () => MockClient((_) async => throw StateError('unexpected request')),
    );

    expect(results, [false, false, false, false]);
  });
}
