import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/modules/user/borrow_request/view/borrow_request.dart';

// หน้าจอสร้าง controller เอง จึงจำลอง server ด้วย http.runWithClient (key = "METHOD /path")
// และจำลอง flutter_secure_storage ให้อ่าน token ได้
Future<void> runApp(
  WidgetTester tester,
  Map<String, http.Response> routes,
  List<http.Request> log,
  Widget screen,
  Future<void> Function() body,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async => call.method == 'read' ? 'test-token' : null,
  );
  await http.runWithClient(() async {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
    await body();
  }, () => MockClient((request) async {
        log.add(request);
        return routes['${request.method} ${request.url.path}'] ??
            http.Response('{}', 404);
      }));
}

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

Color? bg(WidgetTester tester, String label) => tester
    .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, label))
    .style
    ?.backgroundColor
    ?.resolve({});

List<String> calls(List<http.Request> log) =>
    log.map((r) => '${r.method} ${r.url.path}').toList();

Map<String, dynamic> asset({String status = 'ready'}) => {
      'id': 4,
      'owner_id': 9,
      'owner_username': 'alex',
      'name': 'Camera',
      'description': 'Mirrorless camera',
      'status': status,
      'approval': 'approved',
      'down_payment': 200,
      'price': 100,
      'pickup_point': 'Library front desk',
      'return_before': '2099-12-31',
    };

void main() {
  testWidgets('shows the item, price and deposit from GET /api/assets/{id}', (tester) async {
    final log = <http.Request>[];
    await runApp(tester, {
      'GET /api/assets/4': json({'data': asset()}),
    }, log, const BorrowRequestScreen(assetId: 4), () async {
      expect(calls(log), ['GET /api/assets/4']);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.textContaining('Owner: alex'), findsOneWidget);
      expect(find.text('Price / day: 100 Baht'), findsOneWidget);
      expect(find.text('Deposit: 200 Baht'), findsOneWidget);
    });
  });

  testWidgets('Continue to payment is disabled until dates are chosen', (tester) async {
    final log = <http.Request>[];
    await runApp(tester, {
      'GET /api/assets/4': json({'data': asset()}),
    }, log, const BorrowRequestScreen(assetId: 4), () async {
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue to payment'),
      );
      expect(button.onPressed, isNull);
      expect(calls(log).where((c) => c.startsWith('POST')), isEmpty);
    });
  });

  testWidgets('shows error and Retry when the item cannot be loaded', (tester) async {
    await runApp(tester, {
      'GET /api/assets/4': json({'message': 'Asset not found'}, 404),
    }, [], const BorrowRequestScreen(assetId: 4), () async {
      expect(find.text('Asset not found'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  testWidgets('no item selected', (tester) async {
    await runApp(tester, {}, [], const BorrowRequestScreen(), () async {
      expect(find.text('No item selected'), findsOneWidget);
    });
  });
}
