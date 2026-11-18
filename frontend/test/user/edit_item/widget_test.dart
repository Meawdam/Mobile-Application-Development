import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/edit_item/controller/edit_item_controller.dart';
import 'package:frontend/modules/user/edit_item/view/edit_item.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_helpers.dart';

EditItemController _controller(MockClient client) =>
    EditItemController(client: client, authService: FakeAuthservice());

Future<void> _tapSave(WidgetTester tester) async {
  final button = find.text('Save changes');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('loads the item from the API and fills the form', (tester) async {
    useTallScreen(tester);
    late http.Request captured;
    final controller = _controller(
      MockClient((request) async {
        captured = request;
        return jsonResponse({'data': assetJson(id: 1)});
      }),
    );

    await tester.pumpWidget(
      MaterialApp(home: EditItemScreen(assetId: 1, controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(captured.url.path, '/api/assets/1');
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
    final controller = _controller(
      MockClient((request) async => jsonResponse({'message': 'Asset not found'}, 404)),
    );

    await tester.pumpWidget(
      MaterialApp(home: EditItemScreen(assetId: 99, controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asset not found'), findsOneWidget);
    expect(find.text('Save changes'), findsNothing);
  });

  testWidgets('editing and saving calls PATCH, shows success and closes', (
    tester,
  ) async {
    useTallScreen(tester);
    late http.Request patch;
    final controller = _controller(
      MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse({'data': assetJson(id: 1)});
        }
        patch = request;
        return jsonResponse({'message': 'Asset updated successfully'});
      }),
    );

    await pumpPushed(tester, EditItemScreen(assetId: 1, controller: controller));
    await tester.enterText(find.byType(TextField).at(0), 'New camera');
    await _tapSave(tester);

    expect(patch.method, 'PATCH');
    expect(patch.url.path, '/api/assets/1');
    expect(patch.headers['Authorization'], 'Bearer test-token');
    expect((jsonDecode(patch.body) as Map<String, dynamic>)['name'], 'New camera');
    expect(find.text('Changes saved'), findsOneWidget);
    expect(find.byType(EditItemScreen), findsNothing);
  });

  testWidgets('backend error on save stays on the page and shows the message', (
    tester,
  ) async {
    useTallScreen(tester);
    final controller = _controller(
      MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse({'data': assetJson(id: 1)});
        }
        return jsonResponse(
          {'message': 'Cannot edit an asset that is currently borrowed'},
          400,
        );
      }),
    );

    await pumpPushed(tester, EditItemScreen(assetId: 1, controller: controller));
    await _tapSave(tester);

    expect(
      find.text('Cannot edit an asset that is currently borrowed'),
      findsOneWidget,
    );
    expect(find.byType(EditItemScreen), findsOneWidget);
  });
}
