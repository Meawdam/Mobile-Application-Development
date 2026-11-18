import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/wallet/controller/wallet_controller.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('top up sends the amount to the wallet backend', () async {
    var balance = 20.25;
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-token');
      if (request.method == 'GET') {
        expect(request.url.path, '/api/wallet');
        return http.Response(
          jsonEncode({
            'data': {'balance': balance},
          }),
          200,
        );
      }

      expect(request.method, 'POST');
      expect(request.url.path, '/api/wallet/top-up');
      expect(request.headers['Content-Type'], 'application/json');
      final amount = (jsonDecode(request.body) as Map)['amount'] as num;
      balance += amount;
      return http.Response(
        jsonEncode({
          'data': {'balance': balance},
        }),
        200,
      );
    });
    final controller = WalletController(
      client: client,
      authService: _TestAuthService(),
      baseUrl: 'https://example.test',
    );

    await controller.load();
    expect(controller.balance, 20.25);
    expect(await controller.topUpOnline(10.5), isTrue);
    expect(controller.balance, 30.75);
    expect(controller.error, isNull);

    controller.dispose();
    client.close();
  });

  test('top up rejects invalid amounts without making a request', () async {
    final client = MockClient(
      (_) async => throw StateError('Unexpected HTTP request'),
    );
    final controller = WalletController(
      client: client,
      authService: _TestAuthService(),
    );

    expect(await controller.topUpOnline(0), isFalse);
    expect(controller.error, 'Enter a positive amount');
    expect(controller.balance, 0);

    controller.dispose();
    client.close();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}
