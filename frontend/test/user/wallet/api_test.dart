import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/wallet/service/wallet_api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetches balance and submits a top-up to the wallet API', () async {
    var balance = 20.25;
    final service = WalletApiService(
      baseUrl: 'https://example.test',
      authService: _TestAuthService(),
      client: MockClient((request) async {
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
            'message': 'Wallet topped up successfully',
            'data': {'balance': balance, 'topped_up': amount},
          }),
          200,
        );
      }),
    );

    expect((await service.fetchWallet()).balance, 20.25);
    expect((await service.topUp(10.5)).balance, 30.75);
    service.dispose();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}
