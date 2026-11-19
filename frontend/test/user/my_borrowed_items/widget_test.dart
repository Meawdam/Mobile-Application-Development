import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/modules/user/my_borrowed_items/view/my_borrowed_items.dart';

// หน้าจอสร้าง controller เอง จึงจำลอง server ด้วย http.runWithClient (key = "METHOD /path")
// และจำลอง flutter_secure_storage ให้อ่าน token ได้
Future<void> runApp(
  WidgetTester tester,
  Map<String, http.Response> routes,
  List<http.Request> log,
  Widget screen,
  Future<void> Function() body, {
  Route<dynamic>? Function(RouteSettings)? onGenerateRoute,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async => call.method == 'read' ? 'test-token' : null,
  );
  await http.runWithClient(
    () async {
      await tester.pumpWidget(
        MaterialApp(home: screen, onGenerateRoute: onGenerateRoute),
      );
      await tester.pumpAndSettle();
      await body();
    },
    () => MockClient((request) async {
      log.add(request);
      return routes['${request.method} ${request.url.path}'] ??
          http.Response('{}', 404);
    }),
  );
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
  'asset_image': '/uploads/item-$id.jpg',
  'status': status,
  'payment_status': payment,
  'rental_days': 2,
  'deposit_amount': 200,
  'planned_return_date': '2026-11-20',
  'total_amount': 300,
};

void main() {
  final list = json({
    'data': [
      record(1, 'borrowed', 'paid'),
      record(2, 'requested', 'paid'),
      record(3, 'returned_confirmed', 'refunded'),
    ],
  });

  testWidgets('Borrowing tab: blue Request return button asks to confirm', (
    tester,
  ) async {
    final log = <http.Request>[];
    await runApp(
      tester,
      {
        'GET /api/borrows/my': list,
        'PATCH /api/borrows/1/return': json({'message': 'ok'}),
      },
      log,
      const MyBorrowedItemsScreen(),
      () async {
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        final image = tester.widget<Image>(find.byType(Image).first);
        expect(image.image, isA<NetworkImage>());
        expect(find.text('Return by'), findsOneWidget);
        expect(bg(tester, 'Request return'), const Color(0xFF2F4BFF));

        await tester.tap(find.text('Request return'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm return'), findsOneWidget);
        expect(calls(log).contains('PATCH /api/borrows/1/return'), isFalse);

        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(calls(log).contains('PATCH /api/borrows/1/return'), isTrue);
      },
    );
  });

  testWidgets('returning from borrow details refreshes the borrow status', (
    tester,
  ) async {
    final log = <http.Request>[];
    final routes = <String, http.Response>{
      'GET /api/borrows/my': json({
        'data': [record(1, 'approved', 'paid')],
      }),
    };

    await runApp(
      tester,
      routes,
      log,
      const MyBorrowedItemsScreen(),
      () async {
        expect(
          find.text('Approved - open details to confirm receipt'),
          findsOneWidget,
        );
        await tester.tap(find.text('Item 1'));
        await tester.pumpAndSettle();

        routes['GET /api/borrows/my'] = json({
          'data': [record(1, 'borrowed', 'paid')],
        });
        await tester.tap(find.text('Back to borrowed items'));
        await tester.pumpAndSettle();

        expect(
          calls(log).where((call) => call == 'GET /api/borrows/my').length,
          2,
        );
        expect(find.text('Request return'), findsOneWidget);
      },
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to borrowed items'),
          ),
        ),
      ),
    );
  });

  testWidgets(
    'Pending tab: red Cancel button cancels a paid request and refunds',
    (tester) async {
      final log = <http.Request>[];
      await runApp(
        tester,
        {
          'GET /api/borrows/my': list,
          'PATCH /api/borrows/2/cancel': json({
            'message':
                'Borrow request cancelled and payment refunded to wallet',
          }),
        },
        log,
        const MyBorrowedItemsScreen(),
        () async {
          await tester.tap(find.text('Pending'));
          await tester.pumpAndSettle();

          expect(find.text('Item 2'), findsOneWidget);
          expect(bg(tester, 'Cancel'), const Color.fromARGB(255, 223, 42, 42));

          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();

          expect(calls(log).contains('PATCH /api/borrows/2/cancel'), isTrue);
          expect(
            find.textContaining('refunded to your wallet'),
            findsOneWidget,
          );
        },
      );
    },
  );

  testWidgets('Returned tab lists returned items without buttons', (
    tester,
  ) async {
    await runApp(
      tester,
      {'GET /api/borrows/my': list},
      [],
      const MyBorrowedItemsScreen(),
      () async {
        await tester.tap(find.text('Returned'));
        await tester.pumpAndSettle();

        expect(find.text('Item 3'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
      },
    );
  });

  testWidgets('shows the backend error message', (tester) async {
    await runApp(
      tester,
      {
        'GET /api/borrows/my': json({
          'message': 'Invalid or expired token',
        }, 403),
      },
      [],
      const MyBorrowedItemsScreen(),
      () async {
        expect(find.text('Invalid or expired token'), findsOneWidget);
      },
    );
  });
}
