import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/payment/controller/payment_controller.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loadWallet reads the current backend balance', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/wallet');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(
        jsonEncode({
          'data': {'balance': 1500.5},
        }),
        200,
      );
    });
    final controller = PaymentController(
      client: client,
      authService: _TestAuthService(),
      baseUrl: 'https://example.test',
    );

    await controller.loadWallet();

    expect(controller.walletBalance, 1500.5);
    expect(controller.loading, isFalse);
    expect(controller.loadError, isNull);
    controller.dispose();
    client.close();
  });

  test('canPay compares the balance with the total', () {
    final client = MockClient((_) async => throw StateError('Unexpected HTTP'));
    final controller = PaymentController(walletBalance: 500, client: client);

    expect(controller.canPay(400), isTrue);
    expect(controller.canPay(500), isTrue);
    expect(controller.canPay(501), isFalse);
    controller.dispose();
    client.close();
  });

  test(
    'controller loads borrow and wallet then pays through the backend',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        if (request.method == 'GET' && request.url.path == '/api/wallet') {
          return http.Response(
            jsonEncode({
              'data': {'balance': 500},
            }),
            200,
          );
        }
        if (request.method == 'GET' && request.url.path == '/api/borrows/7') {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 7,
                'asset_id': 5,
                'rental_days': 2,
                'rental_amount': 20.25,
                'deposit_amount': 30.5,
                'total_amount': 50.75,
                'status': 'approved',
                'payment_status': 'unpaid',
              },
            }),
            200,
          );
        }

        expect(request.method, 'POST');
        expect(request.url.path, '/api/borrows/7/pay');
        return http.Response(
          jsonEncode({
            'data': {
              'borrow_id': 7,
              'wallet_balance': 449.25,
              'status': 'approved',
              'payment_status': 'paid',
            },
          }),
          200,
        );
      });
      final controller = PaymentController(
        client: client,
        authService: _TestAuthService(),
        baseUrl: 'https://example.test',
      );

      await controller.loadPayment(7);
      expect(controller.walletBalance, 500);
      expect(controller.borrow?.totalAmount, 50.75);
      final result = await controller.confirmPayment(borrowId: 7, total: 999);

      expect(result?.borrowId, 7);
      expect(controller.walletBalance, 449.25);
      expect(controller.borrow?.status, 'approved');
      expect(controller.borrow?.paymentStatus, 'paid');
      controller.dispose();
      client.close();
    },
  );

  test('rejects insufficient balance without submitting payment', () async {
    var paid = false;
    final client = MockClient((request) async {
      if (request.url.path == '/api/wallet') {
        return http.Response(
          jsonEncode({
            'data': {'balance': 10},
          }),
          200,
        );
      }
      if (request.url.path == '/api/borrows/7') {
        return http.Response(
          jsonEncode({
            'data': {
              'id': 7,
              'asset_id': 5,
              'rental_days': 2,
              'total_amount': 50,
              'status': 'requested',
              'payment_status': 'unpaid',
            },
          }),
          200,
        );
      }
      paid = true;
      throw StateError('Payment must not be submitted');
    });
    final controller = PaymentController(
      client: client,
      authService: _TestAuthService(),
      baseUrl: 'https://example.test',
    );

    await controller.loadPayment(7);
    final result = await controller.confirmPayment(borrowId: 7, total: 50);

    expect(result, isNull);
    expect(paid, isFalse);
    expect(controller.error, 'Insufficient wallet balance');
    expect(controller.walletBalance, 10);
    controller.dispose();
    client.close();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}
