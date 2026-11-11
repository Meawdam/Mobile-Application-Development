import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/payment/controller/payment_controller.dart';
import 'package:frontend/modules/admin/payment/model/payment_model.dart';

void main() {
  group('PaymentController Tests', () {
    final sampleTransactions = [
      PaymentTransaction(
        title: 'Deposit Refunded - Lab Coat',
        user: 'Anucha Khetthong',
        time: '28 Oct. 14:30',
        amount: '-฿500.00',
        isIncome: false,
        isPending: false,
      ),
      PaymentTransaction(
        title: 'Deposit Held - Microscope',
        user: 'Pimchanok Sriboon',
        time: '30 Oct. 10:15',
        amount: '+฿1,500.00',
        isIncome: true,
        isPending: true,
      ),
    ];

    test('filterTransactions should return only pending refund items', () {
      final controller = PaymentController();
      final result = controller.filterTransactions(
        sampleTransactions,
        'Pending Refund',
      );

      expect(result.length, 1);
      expect(result.first.user, 'Pimchanok Sriboon');
    });

    test('validateAmount should return true for valid amounts', () {
      final controller = PaymentController();
      expect(controller.validateAmount(500.0), true);
      expect(controller.validateAmount(0.0), false);
    });
  });
}
