// ทดสอบหน้า Requests & Returns ที่เจ้าของกด "Confirm return"
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/requests_returns/controller/requests_returns_controller.dart';
import 'package:frontend/modules/user/requests_returns/view/requests_returns.dart';
import 'package:http/testing.dart';

import '../../helpers/test_helpers.dart';

Future<void> _pump(
  WidgetTester tester,
  List<String> calls, {
  int patchStatus = 200,
  String patchMessage = 'Return confirmed',
}) async {
  useTallScreen(tester);
  final controller = RequestsReturnsController(
    client: MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      if (request.method == 'PATCH') {
        return jsonResponse({'message': patchMessage}, patchStatus);
      }
      return jsonResponse({
        'data': [
          borrowJson(id: 2, assetName: 'Camera', status: 'returned_pending'),
          borrowJson(id: 3, assetName: 'Tripod', status: 'borrowed'),
        ],
      });
    }),
    authService: FakeAuthservice(),
  );

  await tester.pumpWidget(
    MaterialApp(home: RequestsReturnsScreen(controller: controller)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows waiting returns and borrowed items from the API', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(tester, calls);

    expect(calls, contains('GET /api/borrows/lending'));
    expect(find.text('Requests & Returns'), findsOneWidget);
    expect(find.text('Waiting for Response'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Tripod'), findsOneWidget);
    expect(find.text('Confirm return'), findsOneWidget);
  });

  testWidgets('Confirm return calls PATCH confirm-return and updates the list', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(tester, calls);

    await tester.tap(find.text('Confirm return'));
    await tester.pumpAndSettle();

    expect(calls, contains('PATCH /api/borrows/2/confirm-return'));
    expect(find.text('Return confirmed'), findsOneWidget);
    expect(find.text('Confirm return'), findsNothing);
  });

  testWidgets('backend refusal shows its message and keeps the button', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(
      tester,
      calls,
      patchStatus: 403,
      patchMessage: 'Forbidden: You are not the owner of this asset',
    );

    await tester.tap(find.text('Confirm return'));
    await tester.pumpAndSettle();

    expect(
      find.text('Forbidden: You are not the owner of this asset'),
      findsOneWidget,
    );
    expect(find.text('Confirm return'), findsOneWidget);
  });
}
