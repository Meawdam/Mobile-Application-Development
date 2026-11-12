import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/payment/controller/payment_controller.dart';

import '../../helpers/test_fakes.dart';

void main() {
  test('1. loadWallet reads the current balance', () async {
    final controller = PaymentController(
      walletApi: FakeWalletApi(balance: 1500),
      borrowApi: FakeBorrowApi(),
    );

    await controller.loadWallet();

    expect(controller.walletBalance, 1500);
    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
  });

  test('2. canPay compares wallet balance to total', () {
    final controller = PaymentController(
      walletApi: FakeWalletApi(balance: 500),
      borrowApi: FakeBorrowApi(),
    );
    controller.walletBalance = 500;

    expect(controller.canPay(400), isTrue);
    expect(controller.canPay(500), isTrue);
    expect(controller.canPay(501), isFalse);
  });

  test('3. confirmPayment succeeds and updates balance', () async {
    final borrowApi = FakeBorrowApi();
    final controller = PaymentController(
      walletApi: FakeWalletApi(balance: 1000),
      borrowApi: borrowApi,
    );
    await controller.loadWallet();

    final result = await controller.confirmPayment(borrowId: 7, total: 800);

    expect(result, isNotNull);
    expect(result!.borrowId, 7);
    expect(borrowApi.lastPaidId, 7);
    expect(controller.walletBalance, 200);
  });

  test('4. confirmPayment rejects insufficient balance', () async {
    final controller = PaymentController(
      walletApi: FakeWalletApi(balance: 100),
      borrowApi: FakeBorrowApi(),
    );
    await controller.loadWallet();

    final result = await controller.confirmPayment(borrowId: 7, total: 800);

    expect(result, isNull);
    expect(controller.error, 'Insufficient wallet balance');
  });

  test('5. confirmPayment stores API payment errors', () async {
    final borrowApi = FakeBorrowApi()..throwOnPay = true;
    final controller = PaymentController(
      walletApi: FakeWalletApi(balance: 1000),
      borrowApi: borrowApi,
    );
    await controller.loadWallet();

    final result = await controller.confirmPayment(borrowId: 7, total: 100);

    expect(result, isNull);
    expect(controller.error, 'payment failed');
  });
}
