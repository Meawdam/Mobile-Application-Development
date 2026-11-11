class PaymentTransaction {
  final String title;
  final String user;
  final String time;
  final String amount;
  final bool isIncome;
  final bool isPending;

  PaymentTransaction({
    required this.title,
    required this.user,
    required this.time,
    required this.amount,
    required this.isIncome,
    required this.isPending,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      title: json['title'] ?? '',
      user: json['user'] ?? '',
      time: json['time'] ?? '',
      amount: json['amount'] ?? '',
      isIncome: json['isIncome'] ?? false,
      isPending: json['isPending'] ?? false,
    );
  }
}
