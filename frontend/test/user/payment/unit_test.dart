import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/payment/controller/payment_controller.dart';
import 'package:frontend/modules/user/payment/service/payment_api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loadWallet reads the current local balance', () async {
    final controller = PaymentController(walletBalance: 1500);

    await controller.loadWallet();

    expect(controller.walletBalance, 1500);
    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
  });

  test('canPay compares the balance with the total', () {
    final controller = PaymentController(walletBalance: 500);

    expect(controller.canPay(400), isTrue);
    expect(controller.canPay(500), isTrue);
    expect(controller.canPay(501), isFalse);
  });

  test('confirmPayment deducts the total and marks the borrow paid', () async {
    final borrows = <BorrowModel>[
      const BorrowModel(
        id: 7,
        assetId: 5,
        rentalDays: 2,
        status: 'requested',
        paymentStatus: 'unpaid',
      ),
    ];
    final controller = PaymentController(walletBalance: 1000, borrows: borrows);

    final result = await controller.confirmPayment(borrowId: 7, total: 800);

    expect(result, isNotNull);
    expect(result!.borrowId, 7);
    expect(controller.walletBalance, 200);
    expect(borrows.single.status, 'borrowed');
    expect(borrows.single.paymentStatus, 'paid');
  });

  test('confirmPayment rejects an insufficient balance', () async {
    final borrows = <BorrowModel>[
      const BorrowModel(
        id: 7,
        assetId: 5,
        rentalDays: 2,
        status: 'requested',
        paymentStatus: 'unpaid',
      ),
    ];
    final controller = PaymentController(walletBalance: 100, borrows: borrows);

    final result = await controller.confirmPayment(borrowId: 7, total: 800);

    expect(result, isNull);
    expect(controller.error, 'Insufficient wallet balance');
    expect(controller.walletBalance, 100);
    expect(borrows.single.paymentStatus, 'unpaid');
  });

  test('confirmPayment reports a missing borrow', () async {
    final controller = PaymentController(walletBalance: 1000);

    final result = await controller.confirmPayment(borrowId: 7, total: 100);

    expect(result, isNull);
    expect(controller.error, 'Borrow not found');
  });

  test(
    'controller loads borrow and wallet then pays through its API service',
    () async {
      final service = PaymentApiService(
        authService: _TestAuthService(),
        client: MockClient((request) async {
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
        }),
      );
      final controller = PaymentController(apiService: service);

      await controller.loadPayment(7);
      expect(controller.walletBalance, 500);
      expect(controller.borrow?.totalAmount, 50.75);
      final result = await controller.confirmPayment(borrowId: 7, total: 999);

      expect(result?.borrowId, 7);
      expect(controller.walletBalance, 449.25);
      expect(controller.borrow?.status, 'approved');
      expect(controller.borrow?.paymentStatus, 'paid');
      controller.dispose();
      service.dispose();
    },
  );
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}
