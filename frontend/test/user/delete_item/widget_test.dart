// ทดสอบชีตยืนยันลบ (bottom sheet) ในหน้า My Lending Items
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:frontend/modules/user/my_lending_items/view/my_lending_items.dart';
import 'package:http/testing.dart';

import '../../helpers/test_helpers.dart';

Future<void> _openSheet(
  WidgetTester tester,
  List<String> calls, {
  int deleteStatus = 200,
  String deleteMessage = 'Asset deleted successfully',
}) async {
  useTallScreen(tester);
  final controller = MyLendingController(
    client: MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      if (request.method == 'DELETE') {
        return jsonResponse({'message': deleteMessage}, deleteStatus);
      }
      return jsonResponse({'data': [assetJson(id: 1, name: 'My camera')]});
    }),
    authService: FakeAuthservice(),
  );

  await tester.pumpWidget(
    MaterialApp(home: MyLendingItemsScreen(controller: controller)),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.delete_outline));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping delete opens the confirmation sheet', (tester) async {
    final calls = <String>[];
    await _openSheet(tester, calls);

    expect(find.text('Delete "My camera"?'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);
    expect(find.text('Delete item'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Cancel closes the sheet and does not call DELETE', (tester) async {
    final calls = <String>[];
    await _openSheet(tester, calls);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete "My camera"?'), findsNothing);
    expect(find.text('My camera'), findsOneWidget);
    expect(calls.where((c) => c.startsWith('DELETE')), isEmpty);
  });

  testWidgets('Delete item calls DELETE /api/assets/1 and removes the item', (
    tester,
  ) async {
    final calls = <String>[];
    await _openSheet(tester, calls);

    await tester.tap(find.text('Delete item'));
    await tester.pumpAndSettle();

    expect(calls, contains('DELETE /api/assets/1'));
    expect(find.text('Item deleted'), findsOneWidget);
    expect(find.text('My camera'), findsNothing);
    expect(find.text('No items to display'), findsOneWidget);
  });

  testWidgets('backend refusal shows its message and keeps the item', (
    tester,
  ) async {
    final calls = <String>[];
    await _openSheet(
      tester,
      calls,
      deleteStatus: 409,
      deleteMessage: 'Cannot delete an asset that is currently borrowed',
    );

    await tester.tap(find.text('Delete item'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cannot delete an asset that is currently borrowed'),
      findsOneWidget,
    );
    expect(find.text('My camera'), findsOneWidget);
  });
}
