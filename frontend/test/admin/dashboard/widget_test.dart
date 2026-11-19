import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/dashboard/controller/dashboard_controller.dart';
import 'package:frontend/modules/admin/dashboard/model/dashboard_model.dart';
import 'package:frontend/modules/admin/dashboard/view/dashboard_view.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardController extends Mock implements DashboardController {}

void main() {
  testWidgets('Admin dashboard is displayed', (tester) async {
    final controller = MockDashboardController();
    when(() => controller.fetchDashboardStats()).thenAnswer(
      (_) async =>
          DashboardStats(approvedCount: 3, pendingCount: 2, borrowedCount: 1),
    );

    await tester.pumpWidget(
      MaterialApp(home: AdminDashboardScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    expect(find.text('Good day, Admin'), findsOneWidget);
    expect(find.text('Platform overview'), findsOneWidget);
    expect(find.text('Approved items'), findsOneWidget);
    expect(find.text('Waiting for review'), findsOneWidget);
  });
}
