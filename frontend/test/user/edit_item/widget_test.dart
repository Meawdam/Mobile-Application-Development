import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/edit_item/controller/edit_item_controller.dart';
import 'package:frontend/modules/user/edit_item/view/edit_item.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_helpers.dart';

EditItemController _controller(MockHttpClient client) =>
    EditItemController(client: client, authService: mockAuthservice());

Future<void> _tapSave(WidgetTester tester) async {
  final button = find.text('Save changes');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(registerMockFallbacks);

  testWidgets('loads the item from the API and fills the form', (tester) async {
    useTallScreen(tester);
    final client = MockHttpClient();
    stubGet(client, '/api/assets/1', jsonResponse({'data': assetJson(id: 1)}));

    await tester.pumpWidget(
      MaterialApp(
        home: EditItemScreen(assetId: 1, controller: _controller(client)),
      ),
    );
    await tester.pumpAndSettle();

    verify(
      () => client.get(apiUri('/api/assets/1'), headers: expectedHeaders()),
    ).called(1);
    expect(find.text('My camera'), findsOneWidget);
    expect(find.text('Digital camera'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('Canteen'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('shows the backend message when the item cannot be loaded', (
    tester,
  ) async {
    useTallScreen(tester);
    final client = MockHttpClient();
    stubGet(
      client,
      '/api/assets/99',
      jsonResponse({'message': 'Asset not found'}, 404),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditItemScreen(assetId: 99, controller: _controller(client)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asset not found'), findsOneWidget);
    expect(find.text('Save changes'), findsNothing);
  });

  testWidgets('editing and saving calls PATCH, shows success and closes', (
    tester,
  ) async {
    useTallScreen(tester);
    final client = MockHttpClient();
    stubGet(client, '/api/assets/1', jsonResponse({'data': assetJson(id: 1)}));
    stubPatch(
      client,
      '/api/assets/1',
      jsonResponse({'message': 'Asset updated successfully'}),
      withBody: true,
    );

    await pumpPushed(
      tester,
      EditItemScreen(assetId: 1, controller: _controller(client)),
    );
    await tester.enterText(find.byType(TextField).at(0), 'New camera');
    await _tapSave(tester);

    final body =
        verify(
              () => client.patch(
                apiUri('/api/assets/1'),
                headers: expectedHeaders(),
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as String;
    expect((jsonDecode(body) as Map<String, dynamic>)['name'], 'New camera');
    expect(find.text('Changes saved'), findsOneWidget);
    expect(find.byType(EditItemScreen), findsNothing);
  });

  testWidgets('backend error on save stays on the page and shows the message', (
    tester,
  ) async {
    useTallScreen(tester);
    final client = MockHttpClient();
    stubGet(client, '/api/assets/1', jsonResponse({'data': assetJson(id: 1)}));
    stubPatch(
      client,
      '/api/assets/1',
      jsonResponse({
        'message': 'Cannot edit an asset that is currently borrowed',
      }, 400),
      withBody: true,
    );

    await pumpPushed(
      tester,
      EditItemScreen(assetId: 1, controller: _controller(client)),
    );
    await _tapSave(tester);

    expect(
      find.text('Cannot edit an asset that is currently borrowed'),
      findsOneWidget,
    );
    expect(find.byType(EditItemScreen), findsOneWidget);
  });
}
