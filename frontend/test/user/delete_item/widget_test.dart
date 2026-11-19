// ทดสอบชีตยืนยันลบ (bottom sheet) ในหน้า My Lending Items
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:frontend/modules/user/my_lending_items/view/my_lending_items.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_helpers.dart';

Future<MockHttpClient> _openSheet(
  WidgetTester tester, {
  int deleteStatus = 200,
  String deleteMessage = 'Asset deleted successfully',
}) async {
  useTallScreen(tester);
  final client = MockHttpClient();
  stubGet(
    client,
    '/api/assets/mine',
    jsonResponse({
      'data': [assetJson(id: 1, name: 'My camera')],
    }),
  );
  stubDelete(
    client,
    '/api/assets/1',
    jsonResponse({'message': deleteMessage}, deleteStatus),
  );
  final controller = MyLendingController(
    client: client,
    authService: mockAuthservice(),
  );

  await tester.pumpWidget(
    MaterialApp(home: MyLendingItemsScreen(controller: controller)),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete item'));
  await tester.pumpAndSettle();
  return client;
}

void main() {
  setUpAll(registerMockFallbacks);

  testWidgets('tapping delete opens the confirmation sheet', (tester) async {
    await _openSheet(tester);

    expect(find.text('Delete "My camera"?'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);
    expect(find.text('Delete item'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Cancel closes the sheet and does not call DELETE', (
    tester,
  ) async {
    final client = await _openSheet(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete "My camera"?'), findsNothing);
    expect(find.text('My camera'), findsOneWidget);
    verifyNever(() => client.delete(any(), headers: any(named: 'headers')));
  });

  testWidgets('Delete item calls DELETE /api/assets/1 and removes the item', (
    tester,
  ) async {
    final client = await _openSheet(tester);

    await tester.tap(find.text('Delete item'));
    await tester.pumpAndSettle();

    verify(
      () => client.delete(apiUri('/api/assets/1'), headers: expectedHeaders()),
    ).called(1);
    expect(find.text('Item deleted'), findsOneWidget);
    expect(find.text('My camera'), findsNothing);
    expect(find.text('No items to display'), findsOneWidget);
  });

  testWidgets('backend refusal shows its message and keeps the item', (
    tester,
  ) async {
    await _openSheet(
      tester,
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
