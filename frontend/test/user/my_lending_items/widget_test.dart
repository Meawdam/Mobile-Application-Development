import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:frontend/modules/user/my_lending_items/view/my_lending_items.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_helpers.dart';

MyLendingController _controller(MockClient client) =>
    MyLendingController(client: client, authService: FakeAuthservice());

Future<void> _pump(WidgetTester tester, MyLendingController controller) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: MyLendingItemsScreen(controller: controller)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the items returned by GET /api/assets/mine', (tester) async {
    late http.Request captured;
    await _pump(
      tester,
      _controller(
        MockClient((request) async {
          captured = request;
          return jsonResponse({
            'data': [
              assetJson(id: 1, name: 'My camera'),
              assetJson(id: 2, name: 'My tripod', approval: 'pending'),
            ],
          });
        }),
      ),
    );

    expect(captured.url.path, '/api/assets/mine');
    expect(captured.headers['Authorization'], 'Bearer test-token');
    expect(find.text('My Lending Items'), findsOneWidget);
    expect(find.text('My camera'), findsOneWidget);
    expect(find.text('My tripod'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    expect(find.text('Add Item'), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no items', (tester) async {
    await _pump(
      tester,
      _controller(MockClient((request) async => jsonResponse({'data': []}))),
    );

    expect(find.text('No items to display'), findsOneWidget);
  });

  testWidgets('shows the error text when loading fails', (tester) async {
    await _pump(
      tester,
      _controller(
        MockClient((request) async => jsonResponse({'message': 'Invalid token'}, 403)),
      ),
    );

    expect(find.text('Invalid token'), findsOneWidget);
  });

  testWidgets('shows a connection error when the server is unreachable', (
    tester,
  ) async {
    await _pump(
      tester,
      _controller(
        MockClient((request) async => throw http.ClientException('offline')),
      ),
    );

    expect(find.text('Connection error'), findsOneWidget);
  });
}
