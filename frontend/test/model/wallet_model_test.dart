import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/wallet/wallet_model.dart';

void main() {
  test('fromJson parses int, num and string balances', () {
    expect(WalletModel.fromJson({'balance': 100}).balance, 100);
    expect(WalletModel.fromJson({'balance': 50.9}).balance, 50);
    expect(WalletModel.fromJson({'balance': '250'}).balance, 250);
    expect(WalletModel.fromJson({}).balance, 0);
  });

  test('toJson returns the balance field', () {
    expect(const WalletModel(balance: 75).toJson(), {'balance': 75});
  });
}
