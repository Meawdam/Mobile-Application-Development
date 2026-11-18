import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/wallet/service/wallet_api_service.dart';
import 'package:frontend/modules/user/wallet/view/wallet_view.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('loads balance and tops up using the wallet API', (tester) async {
    var balance = 250.75;
    final service = WalletApiService(
      baseUrl: 'https://example.test',
      authService: _TestAuthService(),
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'data': {'balance': balance},
            }),
            200,
          );
        }

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

    await tester.pumpWidget(
      MaterialApp(home: WalletScreen(apiService: service)),
    );
    await tester.pumpAndSettle();
    expect(find.text('฿250.75'), findsOneWidget);

    await tester.tap(find.text('฿500'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to wallet'));
    await tester.pumpAndSettle();

    expect(find.text('฿750.75'), findsOneWidget);
    expect(find.text('Your wallet has been topped up.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}
