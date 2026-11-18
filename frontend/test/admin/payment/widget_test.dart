import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/dashboard/controller/dashboard_controller.dart';
import 'package:frontend/modules/admin/dashboard/model/dashboard_model.dart';
import 'package:frontend/modules/admin/payment/controller/payment_controller.dart';
import 'package:frontend/modules/admin/payment/view/payment_view.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentController extends Mock implements PaymentController {}

class MockDashboardController extends Mock implements DashboardController {}

void main() {
  testWidgets('Payment screen is displayed', (tester) async {
    final paymentController = MockPaymentController();
    final dashboardController = MockDashboardController();
    when(() => paymentController.fetchTransactions(limit: 4))
        .thenAnswer((_) async => []);
    when(
      () => paymentController.fetchTransactions(
        type: 'deposit_refund',
        status: 'pending',
        limit: 100,
      ),
    ).thenAnswer((_) async => []);
    when(() => dashboardController.fetchDashboardStats()).thenAnswer(
      (_) async =>
          DashboardStats(approvedCount: 0, pendingCount: 0, borrowedCount: 0),
    );

    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentScreen(
          paymentController: paymentController,
          dashboardController: dashboardController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PaymentScreen), findsOneWidget);
    expect(find.text('Payments & refunds'), findsOneWidget);
    expect(find.text('Collected Revenue'), findsOneWidget);
  });
}
