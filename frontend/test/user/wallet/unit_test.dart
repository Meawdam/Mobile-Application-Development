import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/wallet/controller/wallet_controller.dart';
import 'package:frontend/modules/user/wallet/service/wallet_api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('top up adds a positive amount to the balance', () {
    final controller = WalletController(initialBalance: 1500);

    final result = controller.topUp(250);

    expect(result, isTrue);
    expect(controller.balance, 1750);
    expect(controller.error, isNull);
  });

  test('top up rejects zero or negative amounts without changing balance', () {
    final controller = WalletController(initialBalance: 1500);

    expect(controller.topUp(0), isFalse);
    expect(controller.balance, 1500);
    expect(controller.error, 'Enter a positive amount');

    expect(controller.topUp(-10), isFalse);
    expect(controller.balance, 1500);
  });

  test('controller loads and tops up using the wallet API service', () async {
    var balance = 20.25;
    final service = WalletApiService(
      authService: _TestAuthService(),
      client: MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.path, '/api/wallet');
          return http.Response(
            jsonEncode({
              'data': {'balance': balance},
            }),
            200,
          );
        }

        expect(request.url.path, '/api/wallet/top-up');
        final amount = (jsonDecode(request.body) as Map)['amount'] as num;
        balance += amount;
        return http.Response(
          jsonEncode({
            'data': {'balance': balance},
          }),
          200,
        );
      }),
    );
    final controller = WalletController(apiService: service);

    await controller.load();
    expect(controller.balance, 20.25);
    expect(await controller.topUpOnline(10.5), isTrue);
    expect(controller.balance, 30.75);
    expect(controller.error, isNull);
    controller.dispose();
    service.dispose();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}
