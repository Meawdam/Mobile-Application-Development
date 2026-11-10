class DashboardStats {
  final int approvedCount;
  final int pendingCount;
  final int borrowedCount;

  DashboardStats({
    required this.approvedCount,
    required this.pendingCount,
    required this.borrowedCount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      approvedCount: json['approved_count'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
      borrowedCount: json['borrowed_count'] ?? 0,
    );
  }
}