import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/dashboard/controller/dashboard_controller.dart';
import 'package:frontend/modules/admin/dashboard/model/dashboard_model.dart';

void main() {
  group('DashboardController & Model Tests', () {
    test(
      'hasPendingRequests should return true if count is greater than zero',
      () {
        final controller = DashboardController();
        expect(controller.hasPendingRequests(5), true);
        expect(controller.hasPendingRequests(0), false);
      },
    );

    test('DashboardStats.fromJson should map json correctly', () {
      final json = {
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
      };

      final stats = DashboardStats.fromJson(json);

      expect(stats.approvedCount, 100);
      expect(stats.pendingCount, 5);
      expect(stats.borrowedCount, 10);
      expect(stats.collectedRevenue, 1500.5);
      expect(stats.heldDeposits, 500);
      expect(stats.pendingRefunds, 2);
      expect(stats.processedRefunds, 300);
      expect(stats.borrowingVolume.single.count, 4);
    });
  });
}
