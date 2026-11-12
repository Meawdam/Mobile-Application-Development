class BorrowModel {
  final int id;
  final int assetId;
  final String? assetName;
  final String? ownerName;
  final String? borrowerName;
  final String? pickupPoint;
  final String? pickupDate;
  final String? plannedReturnDate;
  final int rentalDays;
  final String? lendingEndDate;
  final num? pricePerDay;
  final num? rentalSubtotal;
  final num? deposit;
  final num? totalAmount;
  final num? fineAmount;
  final String status;
  final String paymentStatus;

  const BorrowModel({
    required this.id,
    required this.assetId,
    this.assetName,
    this.ownerName,
    this.borrowerName,
    this.pickupPoint,
    this.pickupDate,
    this.plannedReturnDate,
    required this.rentalDays,
    this.lendingEndDate,
    this.pricePerDay,
    this.rentalSubtotal,
    this.deposit,
    this.totalAmount,
    this.fineAmount,
    required this.status,
    required this.paymentStatus,
  });

  factory BorrowModel.fromJson(Map<String, dynamic> json) {
    return BorrowModel(
      id: _asInt(json['id']),
      assetId: _asInt(json['asset_id']),
      assetName: json['asset_name']?.toString(),
      ownerName: json['owner_name']?.toString(),
      borrowerName: json['borrower_name']?.toString(),
      pickupPoint: json['pickup_point']?.toString(),
      pickupDate: _asDate(json['pickup_date']),
      plannedReturnDate: _asDate(json['planned_return_date']),
      rentalDays: _asInt(json['rental_days']),
      lendingEndDate: _asDate(
        json['lending_end_date'] ?? json['return_before'],
      ),
      pricePerDay: _asNumOrNull(json['price_per_day']),
      rentalSubtotal: _asNumOrNull(
        json['rental_amount'] ?? json['rental_subtotal'],
      ),
      deposit: _asNumOrNull(
        json['deposit_amount'] ?? json['deposit'] ?? json['down_payment'],
      ),
      totalAmount: _asNumOrNull(json['total_amount']),
      fineAmount: _asNumOrNull(json['fine_amount']),
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static num? _asNumOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  static String? _asDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString();
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }
}
