import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/approve_items/view/approve_items_view.dart';


void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });


  Future<void> openPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));


    await tester.pumpWidget(
      const MaterialApp(
        home: ApproveItemsPage(),
      ),
    );


    await tester.pumpAndSettle();
  }


  Future<void> openFirstItem(WidgetTester tester) async {
    final firstItem = find.byType(InkWell).first;


    expect(firstItem, findsOneWidget);


    await tester.tap(firstItem);
    await tester.pumpAndSettle();


    expect(find.text('Item Details'), findsOneWidget);
  }


  testWidgets('ApproveItemsPage renders correctly', (tester) async {
    await openPage(tester);


    expect(find.text('Approve Items'), findsOneWidget);
    expect(
      find.text('Review and approve submitted items'),
      findsOneWidget,
    );
    expect(find.text('Pending'), findsOneWidget);


    await tester.binding.setSurfaceSize(null);
  });


  testWidgets('Opens item details when an item is tapped', (tester) async {
    await openPage(tester);


    await openFirstItem(tester);


    expect(
      find.text('Rejection reason (required when rejecting)'),
      findsOneWidget,
    );
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);


    await tester.binding.setSurfaceSize(null);
  });


  testWidgets('Reject requires a reason', (tester) async {
    await openPage(tester);


    await openFirstItem(tester);


    await tester.tap(find.text('Reject'));
    await tester.pump();


    expect(
      find.text('Please enter a reason for rejection.'),
      findsOneWidget,
    );


    await tester.binding.setSurfaceSize(null);
  });


  testWidgets('Approve item after confirmation', (tester) async {
    await openPage(tester);


    await openFirstItem(tester);


    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();


    expect(find.text('Approve Item'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);


    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();


    expect(
      find.text('Item approved successfully!'),
      findsOneWidget,
    );


    await tester.binding.setSurfaceSize(null);
  });
}