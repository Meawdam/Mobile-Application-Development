class WalletModel {
  final int balance;

  const WalletModel({required this.balance});

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final balance = json['balance'];

    return WalletModel(balance: balance.toInt());
  }

  Map<String, dynamic> toJson() => {'balance': balance};
}
