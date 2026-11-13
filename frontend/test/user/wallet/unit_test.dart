import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/wallet/controller/wallet_controller.dart';

void main() {
  test('top up adds a positive amount to the balance', () {
    final controller = WalletController(initialBalance: 1500);

    final result = controller.topUp(250);

    expect(result, isTrue);
    expect(controller.balance, 1750);
    expect(controller.error, isNull);
  });

  test('top up rejects zero or negative amounts without changing balance', () {
    final controller = WalletController(initialBalance: 1500);

    expect(controller.topUp(0), isFalse);
    expect(controller.balance, 1500);
    expect(controller.error, 'Enter a positive amount');

    expect(controller.topUp(-10), isFalse);
    expect(controller.balance, 1500);
  });
}
