import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/modules/user/requests_returns/view/requests_returns.dart';

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

Map<String, dynamic> record(int id, String status, String payment) => {
      'id': id,
      'asset_id': id + 100,
      'asset_name': 'Item $id',
      'borrower_name': 'borrower$id',
      'status': status,
      'payment_status': payment,
      'rental_days': 1,
      'planned_return_date': '2026-11-20',
    };

void main() {
  final list = json({
    'data': [
      record(1, 'requested', 'paid'),
      record(2, 'cancelled', 'refunded'),
      record(3, 'returned_pending', 'paid'),
    ],
  });

  testWidgets('Waiting for Response: blue Approve, red Reject, red Cancel text', (tester) async {
    await runApp(tester, {'GET /api/borrows/owner': list}, [], const RequestsReturnsScreen(), () async {
      expect(find.text('Item 1'), findsOneWidget);
      expect(bg(tester, 'Approve'), const Color(0xFF2F4BFF));
      expect(bg(tester, 'Reject'), const Color.fromARGB(255, 223, 42, 42));

      // คำขอที่ผู้ยืมยกเลิก: ข้อความ Cancel สีแดงด้านขวา ไม่มีปุ่ม
      final cancel = tester.widget<Text>(find.text('Cancel'));
      expect(cancel.style?.color, const Color.fromARGB(255, 223, 42, 42));
    });
  });

  testWidgets('Approve calls the API', (tester) async {
    final log = <http.Request>[];
    await runApp(tester, {
      'GET /api/borrows/owner': list,
      'PATCH /api/borrows/1/approve': json({'message': 'ok'}),
    }, log, const RequestsReturnsScreen(), () async {
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(calls(log).contains('PATCH /api/borrows/1/approve'), isTrue);
    });
  });

  testWidgets('Reject asks for a reason and sends it', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final log = <http.Request>[];
    await runApp(tester, {
      'GET /api/borrows/owner': list,
      'PATCH /api/borrows/1/reject': json({'message': 'ok'}),
    }, log, const RequestsReturnsScreen(), () async {
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      expect(find.text('Reject request'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Item is broken');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reject').last);
      await tester.pumpAndSettle();

      final reject = log.firstWhere((r) => r.url.path == '/api/borrows/1/reject');
      expect(jsonDecode(reject.body), {'reason': 'Item is broken'});
    });
  });

  testWidgets('Reject without a reason does not call the API', (tester) async {
    final log = <http.Request>[];
    await runApp(tester, {'GET /api/borrows/owner': list}, log, const RequestsReturnsScreen(), () async {
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reject').last);
      await tester.pumpAndSettle();

      expect(calls(log).where((c) => c.startsWith('PATCH')), isEmpty);
      expect(find.text('A reason is required to reject a request'), findsOneWidget);
    });
  });

  testWidgets('Borrowed Items: blue Confirm button confirms the return', (tester) async {
    final log = <http.Request>[];
    await runApp(tester, {
      'GET /api/borrows/owner': list,
      'PATCH /api/borrows/3/confirm-return': json({'message': 'ok'}),
    }, log, const RequestsReturnsScreen(), () async {
      expect(bg(tester, 'Confirm'), const Color(0xFF2F4BFF));

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(calls(log).contains('PATCH /api/borrows/3/confirm-return'), isTrue);
    });
  });
}
