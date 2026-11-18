import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/payment/controller/payment_controller.dart';
import 'package:frontend/modules/user/payment/service/payment_api_service.dart';
import 'package:frontend/modules/user/payment/view/payment.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('shows backend payment details and confirms payment', (
    tester,
  ) async {
    var walletBalance = 420.75;
    final service = PaymentApiService(
      baseUrl: 'https://example.test',
      authService: _TestAuthService(),
      client: MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/wallet') {
          return http.Response(
            jsonEncode({
              'data': {'balance': walletBalance},
            }),
            200,
          );
        }
        if (request.method == 'GET' && request.url.path == '/api/borrows/17') {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 17,
                'asset_id': 5,
                'pickup_date': '2030-01-01',
                'planned_return_date': '2030-01-02',
                'rental_days': 2,
                'lending_end_date': '2030-01-10',
                'rental_amount': 20.5,
                'deposit_amount': 30.25,
                'total_amount': 50.75,
                'status': 'approved',
                'payment_status': 'unpaid',
              },
            }),
            200,
          );
        }

        expect(request.method, 'POST');
        expect(request.url.path, '/api/borrows/17/pay');
        walletBalance = 370;
        return http.Response(
          jsonEncode({
            'message': 'Payment completed',
            'data': {
              'borrow_id': 17,
              'total_amount': 50.75,
              'wallet_balance': walletBalance,
              'payment_status': 'paid',
              'status': 'approved',
            },
          }),
          200,
        );
      }),
    );

    final controller = PaymentController(apiService: service);
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentScreen(
          args: const {'borrowId': 17, 'total': 999},
          controller: controller,
        ),
        routes: {
          '/borrow-details': (_) =>
              const Scaffold(body: Text('Borrow details opened')),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('฿50.75'), findsOneWidget);
    expect(find.text('฿20.50'), findsOneWidget);
    expect(find.text('฿30.25'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Wallet balance'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('฿420.75 available'), findsOneWidget);

    await tester.tap(find.text('Pay from wallet'));
    await tester.pumpAndSettle();

    expect(find.text('Borrow details opened'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    service.dispose();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}
