import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/wallet/wallet_model.dart';
import 'package:frontend/modules/user/wallet/controller/wallet_controller.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/wallet_api.dart';

class _FakeWalletApi extends WalletApi {
  int balance = 0;

  @override
  Future<WalletModel> getWallet() async => WalletModel(balance: balance);

  @override
  Future<WalletModel> topUp(int amount) async {
    if (amount <= 0) {
      throw const ApiException(400, 'amount must be a positive whole number');
    }
    balance += amount;
    return WalletModel(balance: balance);
  }
}

void main() {
  test('1. starts with a zero balance by default', () {
    final controller = WalletController(walletApi: _FakeWalletApi());
    expect(controller.balance, 0);
  });

  test('2. adds a positive top-up to the wallet balance', () async {
    final controller = WalletController(walletApi: _FakeWalletApi());
    expect(await controller.topUp(100), isTrue);
    expect(controller.balance, 100);
  });

  test('3. rejects zero or negative top-ups without changing the balance',
      () async {
    final controller = WalletController(walletApi: _FakeWalletApi());
    expect(await controller.topUp(0), isFalse);
    expect(await controller.topUp(-50), isFalse);
    expect(controller.balance, 0);
  });
}
