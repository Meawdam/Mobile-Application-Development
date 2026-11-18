import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/approve_items/controller/approve_items_controller.dart';
import 'package:frontend/modules/admin/approve_items/view/approve_items_view.dart';
import 'package:mocktail/mocktail.dart';

class MockApproveItemsController extends Mock
    implements ApproveItemsController {}

void main() {
  testWidgets('Approve items page is displayed', (tester) async {
    final controller = MockApproveItemsController();
    when(() => controller.items).thenReturn([]);
    when(() => controller.pendingCount).thenReturn(0);
    when(() => controller.isLoading).thenReturn(false);
    when(() => controller.errorMessage).thenReturn(null);
    when(() => controller.fetchItems()).thenAnswer((_) async {});

    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: ApproveItemsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ApproveItemsPage), findsOneWidget);
    expect(find.text('Approve items'), findsOneWidget);
    expect(
      find.text('Review new listings before they appear to users.'),
      findsOneWidget,
    );
  });
}
