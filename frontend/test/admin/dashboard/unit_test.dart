import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/dashboard/controller/dashboard_controller.dart';
import 'package:frontend/modules/admin/dashboard/model/dashboard_model.dart';

void main() {
  test('Pending requests are detected from their count', () {
    final controller = DashboardController();

    expect(controller.hasPendingRequests(1), isTrue);
    expect(controller.hasPendingRequests(0), isFalse);
  });

  test('Dashboard statistics are parsed from the API response', () {
    final stats = DashboardStats.fromJson({
      'assets': {'approved': 100, 'pending': 5, 'borrowed': 10},
      'finance': {
        'collected_revenue': 1500.5,
        'held_deposits': 500,
        'pending_refunds': 2,
        'processed_refunds': 300,
      },
      'borrowing_volume_last_7_days': [
        {'date': '2026-11-17', 'count': 4},
      ],
    });

    expect(stats.approvedCount, 100);
    expect(stats.pendingCount, 5);
    expect(stats.borrowedCount, 10);
    expect(stats.collectedRevenue, 1500.5);
    expect(stats.heldDeposits, 500);
    expect(stats.pendingRefunds, 2);
    expect(stats.processedRefunds, 300);
    expect(stats.borrowingVolume.single.count, 4);
  });
}
