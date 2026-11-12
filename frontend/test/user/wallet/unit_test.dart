import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/wallet/controller/wallet_controller.dart';

void main() {
  test('1. starts with a zero balance by default', () {
    final controller = WalletController();

    expect(controller.balance, 0);
  });

  test('2. adds a positive top-up to the wallet balance', () {
    final controller = WalletController();

    expect(controller.topUp(100), isTrue);
    expect(controller.balance, 100);
  });

  test('3. rejects zero or negative top-ups without changing the balance', () {
    final controller = WalletController();

    expect(controller.topUp(0), isFalse);
    expect(controller.topUp(-50), isFalse);
    expect(controller.balance, 0);
  });
}
