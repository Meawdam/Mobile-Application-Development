import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/dashboard/view/dashboard_view.dart';

void main() {
  testWidgets('Admin dashboard is displayed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminDashboardScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    expect(find.text('Good day, Admin'), findsOneWidget);
    expect(find.text('Platform overview'), findsOneWidget);
    expect(find.text('Approved items'), findsOneWidget);
    expect(find.text('Waiting for review'), findsOneWidget);
  });
}
