import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/approve_items/view/approve_items_view.dart';

void main() {
  testWidgets('Approve items page is displayed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ApproveItemsPage()));
    await tester.pumpAndSettle();

    expect(find.byType(ApproveItemsPage), findsOneWidget);
    expect(find.text('Approve items'), findsOneWidget);
    expect(find.text('Review new listings before they appear to users.'), findsOneWidget);
  });
}
