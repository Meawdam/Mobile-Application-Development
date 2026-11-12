class WalletController {
  int balance = 0;

  bool topUp(int amount) {
    if (amount <= 0) {
      return false;
    }

    balance += amount;
    return true;
  }
}
