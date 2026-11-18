import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/payment/controller/payment_controller.dart';

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
    final controller = PaymentController(
      walletBalance: 1000,
      borrows: borrows,
    );

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
    final controller = PaymentController(
      walletBalance: 100,
      borrows: borrows,
    );

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
}
