import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/payment/service/payment_api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads wallet and borrow data then pays the borrow request', () async {
    final service = PaymentApiService(
      baseUrl: 'https://example.test',
      authService: _TestAuthService(),
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        if (request.method == 'GET' && request.url.path == '/api/wallet') {
          return http.Response(
            jsonEncode({
              'data': {'balance': 420.75},
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
        expect(request.body, isEmpty);
        return http.Response(
          jsonEncode({
            'message': 'Payment completed',
            'data': {
              'borrow_id': 17,
              'total_amount': 50.75,
              'wallet_balance': 370,
              'payment_status': 'paid',
              'status': 'approved',
            },
          }),
          200,
        );
      }),
    );

    expect(await service.fetchWalletBalance(), 420.75);
    final borrow = await service.fetchBorrow(17);
    expect(borrow.totalAmount, 50.75);
    final result = await service.pay(17);
    expect(result.borrowId, 17);
    expect(result.walletBalance, 370);
    expect(result.paymentStatus, 'paid');
    service.dispose();
  });

  test('surfaces payment API errors', () async {
    final service = PaymentApiService(
      authService: _TestAuthService(),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Insufficient wallet balance'}),
          400,
        ),
      ),
    );

    await expectLater(
      service.pay(17),
      throwsA(
        isA<PaymentApiException>().having(
          (error) => error.message,
          'message',
          'Insufficient wallet balance',
        ),
      ),
    );
    service.dispose();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}
