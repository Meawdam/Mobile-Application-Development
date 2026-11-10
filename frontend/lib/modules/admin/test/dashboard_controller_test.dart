import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/controllers/dashboard_controller.dart';
import 'package:frontend/modules/admin/medels/dashboard_model.dart';

void main() {
  group('DashboardController & Model Tests', () {
    test('fetchDashboardStats should return correct stats', () async {
      final controller = DashboardController();
      final stats = await controller.fetchDashboardStats();

      expect(stats.approvedCount, 1248);
      expect(stats.pendingCount, 8);
      expect(stats.borrowedCount, 96);
    });

    test('hasPendingRequests should return true if count is greater than zero', () {
      final controller = DashboardController();
      expect(controller.hasPendingRequests(5), true);
      expect(controller.hasPendingRequests(0), false);
    });

    test('DashboardStats.fromJson should map json correctly', () {
      final json = {
        'approved_count': 100,
        'pending_count': 5,
        'borrowed_count': 10,
      };

      final stats = DashboardStats.fromJson(json);

      expect(stats.approvedCount, 100);
      expect(stats.pendingCount, 5);
      expect(stats.borrowedCount, 10);
    });
  });
}