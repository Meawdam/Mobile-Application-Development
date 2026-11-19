import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:frontend/modules/user/my_lending_items/view/my_lending_items.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_helpers.dart';

MyLendingController _controller(MockHttpClient client) =>
    MyLendingController(client: client, authService: mockAuthservice());

Future<void> _pump(WidgetTester tester, MyLendingController controller) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: MyLendingItemsScreen(controller: controller)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(registerMockFallbacks);

  testWidgets('lists the items returned by GET /api/assets/mine', (
    tester,
  ) async {
    final client = MockHttpClient();
    stubGet(
      client,
      '/api/assets/mine',
      jsonResponse({
        'data': [
          assetJson(id: 1, name: 'My camera'),
          assetJson(id: 2, name: 'My tripod', approval: 'pending'),
        ],
      }),
    );

    await _pump(tester, _controller(client));

    verify(
      () => client.get(apiUri('/api/assets/mine'), headers: expectedHeaders()),
    ).called(1);
    expect(find.text('My Lending Items'), findsOneWidget);
    expect(find.text('My camera'), findsOneWidget);
    expect(find.text('My tripod'), findsOneWidget);
    expect(find.textContaining('Waiting for admin approval'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
    expect(find.text('Add Item'), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no items', (tester) async {
    final client = MockHttpClient();
    stubGet(client, '/api/assets/mine', jsonResponse({'data': []}));

    await _pump(tester, _controller(client));

    expect(find.text('No items to display'), findsOneWidget);
  });

  testWidgets('colors statuses and blocks rejected items with reason', (
    tester,
  ) async {
    final client = MockHttpClient();
    stubGet(
      client,
      '/api/assets/mine',
      jsonResponse({
        'data': [
          assetJson(id: 1, name: 'Ready lamp'),
          assetJson(
            id: 2,
            name: 'Rejected kettle',
            approval: 'not approve',
            approvalMessage: 'Please upload a clearer photo.',
          ),
        ],
      }),
    );

    await _pump(tester, _controller(client));

    expect(find.text('Ready to lend'), findsOneWidget);
    expect(find.text('Not approved'), findsOneWidget);
    expect(
      find.text('Admin reason: Please upload a clearer photo.'),
      findsOneWidget,
    );
    final rejectedTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Rejected kettle'),
        matching: find.byType(ListTile),
      ),
    );
    expect(rejectedTile.onTap, isNull);
  });

  testWidgets('shows the error text when loading fails', (tester) async {
    final client = MockHttpClient();
    stubGet(
      client,
      '/api/assets/mine',
      jsonResponse({'message': 'Invalid token'}, 403),
    );

    await _pump(tester, _controller(client));

    expect(find.text('Invalid token'), findsOneWidget);
  });

  testWidgets('shows a connection error when the server is unreachable', (
    tester,
  ) async {
    final client = MockHttpClient();
    stubGetThrows(client, http.ClientException('offline'));

    await _pump(tester, _controller(client));

    expect(find.text('Connection error'), findsOneWidget);
  });
}
