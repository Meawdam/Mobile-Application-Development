class DashboardStats {
  final int approvedCount;
  final int pendingCount;
  final int borrowedCount;
  final double collectedRevenue;
  final double heldDeposits;
  final int pendingRefunds;
  final double processedRefunds;
  final List<DailyBorrowingStats> borrowingVolume;

  DashboardStats({
    required this.approvedCount,
    required this.pendingCount,
    required this.borrowedCount,
    this.collectedRevenue = 0,
    this.heldDeposits = 0,
    this.pendingRefunds = 0,
    this.processedRefunds = 0,
    this.borrowingVolume = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final assets = json['assets'] is Map
        ? Map<String, dynamic>.from(json['assets'] as Map)
        : json;
    final finance = json['finance'] is Map
        ? Map<String, dynamic>.from(json['finance'] as Map)
        : const <String, dynamic>{};
    final volume = json['borrowing_volume_last_7_days'];

    return DashboardStats(
      approvedCount: _toInt(assets['approved'] ?? json['approved_count']),
      pendingCount: _toInt(assets['pending'] ?? json['pending_count']),
      borrowedCount: _toInt(assets['borrowed'] ?? json['borrowed_count']),
      collectedRevenue: _toDouble(finance['collected_revenue']),
      heldDeposits: _toDouble(finance['held_deposits']),
      pendingRefunds: _toInt(finance['pending_refunds']),
      processedRefunds: _toDouble(finance['processed_refunds']),
      borrowingVolume: volume is List
          ? volume
                .whereType<Map>()
                .map(
                  (item) => DailyBorrowingStats.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DailyBorrowingStats {
  final String date;
  final int count;

  const DailyBorrowingStats({required this.date, required this.count});

  factory DailyBorrowingStats.fromJson(Map<String, dynamic> json) {
    return DailyBorrowingStats(
      date: json['date']?.toString() ?? '',
      count: DashboardStats._toInt(json['count']),
    );
  }
}
