import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/payment/view/payment_view.dart';

void main() {
  testWidgets('Payment screen is displayed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PaymentScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentScreen), findsOneWidget);
    expect(find.text('Payments & refunds'), findsOneWidget);
    expect(find.text('Collected Revenue'), findsOneWidget);
  });
}
