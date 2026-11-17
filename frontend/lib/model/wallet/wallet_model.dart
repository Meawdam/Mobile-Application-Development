class WalletModel {
  final int balance;

  const WalletModel({required this.balance});

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final balance = json['balance'];
    if (balance is int) {
      return WalletModel(balance: balance);
    }
    if (balance is num) {
      return WalletModel(balance: balance.toInt());
    }
    return WalletModel(balance: int.tryParse(balance?.toString() ?? '') ?? 0);
  }

  Map<String, dynamic> toJson() => {'balance': balance};
}
