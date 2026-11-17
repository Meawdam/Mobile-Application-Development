class PaymentTransaction {
  final String id;
  final String title;
  final String user;
  final String time;
  final String amount;
  final bool isIncome;
  final bool isPending;
  final bool isRefundable;

  PaymentTransaction({
    this.id = '',
    required this.title,
    required this.user,
    required this.time,
    required this.amount,
    required this.isIncome,
    required this.isPending,
    this.isRefundable = false,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      user: json['user'] ?? '',
      time: json['time'] ?? '',
      amount: json['amount'] ?? '',
      isIncome: json['isIncome'] ?? false,
      isPending: json['isPending'] ?? false,
      isRefundable: json['isRefundable'] ?? false,
    );
  }
}
