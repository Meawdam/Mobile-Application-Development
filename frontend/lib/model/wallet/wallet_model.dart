class WalletModel {
  final num balance;

  const WalletModel({required this.balance});

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final balance = json['balance'];
    if (balance is num) {
      return WalletModel(balance: balance);
    }
    final parsed = num.tryParse(balance?.toString() ?? '');
    if (parsed == null) {
      throw const FormatException('Invalid wallet balance');
    }
    return WalletModel(balance: parsed);
  }

  Map<String, dynamic> toJson() => {'balance': balance};
}
