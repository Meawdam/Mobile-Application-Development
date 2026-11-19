import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/modules/user/borrow_details/view/borrow_details.dart';

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

Map<String, dynamic> record(String status, String payment) => {
      'id': 12,
      'asset_id': 5,
      'asset_name': 'Camera',
      'owner_name': 'alex',
      'pickup_point': 'Library front desk',
      'planned_return_date': '2026-11-20',
      'rental_days': 2,
      'status': status,
      'payment_status': payment,
    };

Map<String, http.Response> routesFor(String status, String payment) => {
      'GET /api/borrows/12': json({'data': record(status, payment)}),
      'PATCH /api/borrows/12/confirm-received': json({'message': 'ok'}),
      'PATCH /api/borrows/12/return': json({'message': 'ok'}),
    };

void main() {
  testWidgets('timeline is shown first with 4 steps', (tester) async {
    await runApp(tester, routesFor('requested', 'paid'), [],
        const BorrowDetailsScreen(borrowId: 12), () async {
      for (final label in ['Paid', 'Received', 'Borrowed', 'Returned']) {
        expect(find.text(label), findsOneWidget);
      }
      final timelineY = tester.getTopLeft(find.text('Status timeline')).dy;
      final nameY = tester.getTopLeft(find.text('Camera')).dy;
      expect(timelineY, lessThan(nameY));
    });
  });

  testWidgets('paid request waiting for the owner has no Received button', (tester) async {
    await runApp(tester, routesFor('requested', 'paid'), [],
        const BorrowDetailsScreen(borrowId: 12), () async {
      expect(find.widgetWithText(ElevatedButton, 'Received'), findsNothing);
    });
  });

  testWidgets('approved and paid: yellow Received button confirms receipt', (tester) async {
    final log = <http.Request>[];
    await runApp(tester, routesFor('approved', 'paid'), log,
        const BorrowDetailsScreen(borrowId: 12), () async {
      expect(bg(tester, 'Received'), const Color.fromARGB(255, 252, 252, 75));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Received'));
      await tester.pumpAndSettle();

      expect(calls(log).contains('PATCH /api/borrows/12/confirm-received'), isTrue);
    });
  });

  testWidgets('borrowed item shows Request return button', (tester) async {
    final log = <http.Request>[];
    await runApp(tester, routesFor('borrowed', 'paid'), log,
        const BorrowDetailsScreen(borrowId: 12), () async {
      await tester.ensureVisible(find.text('Request return'));
      await tester.tap(find.text('Request return'));
      await tester.pumpAndSettle();

      expect(calls(log).contains('PATCH /api/borrows/12/return'), isTrue);
    });
  });

  testWidgets('return request shows a yellow disabled Pending return button', (tester) async {
    final log = <http.Request>[];
    await runApp(tester, routesFor('returned_pending', 'paid'), log,
        const BorrowDetailsScreen(borrowId: 12), () async {
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Pending return'),
      );

      expect(button.onPressed, isNull);
      expect(
        button.style?.backgroundColor?.resolve({WidgetState.disabled}),
        const Color(0xFFFFF3C4),
      );
      expect(find.text('Confirm return'), findsNothing);
      expect(calls(log).where((call) => call.contains('confirm-return')), isEmpty);
    });
  });

  testWidgets('shows error and Retry when loading fails', (tester) async {
    await runApp(tester, {
      'GET /api/borrows/12': json({'message': 'Borrow record not found'}, 404),
    }, [], const BorrowDetailsScreen(borrowId: 12), () async {
      expect(find.text('Borrow record not found'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  testWidgets('no borrow selected', (tester) async {
    await runApp(tester, {}, [], const BorrowDetailsScreen(), () async {
      expect(find.text('No borrow selected'), findsOneWidget);
    });
  });
}
