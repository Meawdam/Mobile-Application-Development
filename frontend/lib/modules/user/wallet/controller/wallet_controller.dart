import 'package:flutter/foundation.dart';

class WalletController extends ChangeNotifier {
  WalletController({int initialBalance = 0}) : balance = initialBalance;

  int balance;
  String? error;

  bool topUp(int amount) {
    if (amount <= 0) {
      error = 'Enter a positive amount';
      notifyListeners();
      return false;
    }

    balance += amount;
    error = null;
    notifyListeners();
    return true;
  }
}
