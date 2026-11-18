import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/payment/controller/payment_controller.dart';
import 'package:frontend/modules/admin/payment/model/payment_model.dart';

void main() {
  late PaymentController controller;

  setUp(() => controller = PaymentController());

  final transactions = [
    PaymentTransaction(
      id: 'refund-1',
      title: 'Deposit refund',
      user: 'Anucha',
      time: '2026-11-18',
      amount: '-฿500.00',
      isIncome: false,
      isPending: true,
      isRefundable: true,
    ),
    PaymentTransaction(
      id: 'payment-1',
      title: 'Rental payment',
      user: 'Pimchanok',
      time: '2026-11-17',
      amount: '+฿1,500.00',
      isIncome: true,
      isPending: false,
    ),
  ];

  test('Pending Refund filter returns refundable transactions', () {
    final result = controller.filterTransactions(transactions, 'Pending Refund');

    expect(result.map((transaction) => transaction.id), ['refund-1']);
  });

  test('Collected filter returns completed income transactions', () {
    final result = controller.filterTransactions(transactions, 'Collected');

    expect(result.map((transaction) => transaction.id), ['payment-1']);
  });

  test('Amount validation only accepts positive values', () {
    expect(controller.validateAmount(500), isTrue);
    expect(controller.validateAmount(0), isFalse);
    expect(controller.validateAmount(-1), isFalse);
  });
}
