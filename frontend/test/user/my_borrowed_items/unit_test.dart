import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/my_borrowed_items/controller/my_borrowed_controller.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements Authservice {}

void main() {
  // service ปลอมที่คืน token ให้ (ไม่ต้องใช้ secure storage จริง)
  MockAuthService makeService() {
    final service = MockAuthService();
    when(() => service.loadToken()).thenAnswer((_) async => 'test-token');
    return service;
  }

  // รันโค้ดโดยให้ http.get/patch ตอบจาก routes (key = "METHOD /path") แทน server จริง
  Future<T> run<T>(
    Map<String, http.Response> routes,
    List<http.Request> log,
    Future<T> Function() body,
  ) {
    return http.runWithClient(
      body,
      () => MockClient((request) async {
        log.add(request);
        return routes['${request.method} ${request.url.path}'] ??
            http.Response('{}', 404);
      }),
    );
  }

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status);

  Map<String, dynamic> record(
    int id,
    String status,
    String payment,
    num deposit,
  ) {
    return {
      'id': id,
      'asset_id': id + 100,
      'asset_name': 'Item $id',
      'status': status,
      'payment_status': payment,
      'rental_days': 2,
      'deposit_amount': deposit,
      'planned_return_date': '2026-11-20',
      'total_amount': deposit + 100,
    };
  }

  BorrowModel model(int id, String status, String payment, num deposit) =>
      BorrowModel.fromJson(record(id, status, payment, deposit));

  group('grouping', () {
    final controller = MyBorrowedController(
      service: makeService(),
      initialItems: [
        model(1, 'borrowed', 'paid', 500),
        model(2, 'returned_pending', 'paid', 200),
        model(3, 'requested', 'paid', 100),
        model(4, 'returned_confirmed', 'refunded', 50),
        model(5, 'approved', 'paid', 300),
        model(6, 'cancelled', 'unpaid', 80),
      ],
    );

    test('Borrowing tab has approved, borrowed and return-pending items', () {
      expect(controller.borrowing.map((b) => b.id), [1, 2, 5]);
    });

    test('Pending tab has paid requests waiting for the owner', () {
      expect(controller.pending.map((b) => b.id), [3]);
    });

    test('Returned tab has returned items only', () {
      expect(controller.returned.map((b) => b.id), [4]);
    });

    test('held deposit counts paid items that are not finished', () {
      // 500 + 200 + 100 + 300 (รายการที่คืนเสร็จ/ยกเลิกไม่นับ)
      expect(controller.heldDeposit, 1100);
    });
  });

  group('load', () {
    test('calls GET /api/borrows/my with the token and fills items', () async {
      final log = <http.Request>[];
      final controller = MyBorrowedController(service: makeService());

      await run(
        {
          'GET /api/borrows/my': json({
            'data': [record(1, 'borrowed', 'paid', 500)],
          }),
        },
        log,
        controller.load,
      );

      expect(log.single.headers['Authorization'], 'Bearer test-token');
      expect(controller.items.single.id, 1);
      expect(controller.error, isNull);
      expect(controller.loading, isFalse);
    });

    test('shows the backend error message', () async {
      final controller = MyBorrowedController(service: makeService());

      await run(
        {
          'GET /api/borrows/my': json({
            'message': 'Access token required',
          }, 401),
        },
        [],
        controller.load,
      );

      expect(controller.error, 'Access token required');
    });

    test('shows Connection error when the server is unreachable', () async {
      final controller = MyBorrowedController(service: makeService());

      await http.runWithClient(
        controller.load,
        () => MockClient((_) async => throw http.ClientException('down')),
      );

      expect(controller.error, 'Connection error');
    });
  });

  group('actions', () {
    MyBorrowedController makeController() => MyBorrowedController(
      service: makeService(),
      initialItems: [
        model(1, 'borrowed', 'paid', 500),
        model(3, 'requested', 'paid', 100),
      ],
    );

    final reload = json({'data': <Object>[]});

    test('cancel calls PATCH /cancel then reloads the list', () async {
      final log = <http.Request>[];
      final controller = makeController();

      final err = await run(
        {
          'PATCH /api/borrows/3/cancel': json({
            'message':
                'Borrow request cancelled and payment refunded to wallet',
          }),
          'GET /api/borrows/my': reload,
        },
        log,
        () => controller.cancel(3),
      );

      expect(err, isNull);
      expect(log.map((r) => '${r.method} ${r.url.path}'), [
        'PATCH /api/borrows/3/cancel',
        'GET /api/borrows/my',
      ]);
      expect(controller.items, isEmpty);
    });

    test('cancel returns the backend message when it fails', () async {
      final controller = makeController();

      final err = await run(
        {
          'PATCH /api/borrows/3/cancel': json({
            'message': 'Borrow request is no longer available to cancel',
          }, 409),
        },
        [],
        () => controller.cancel(3),
      );

      expect(err, 'Borrow request is no longer available to cancel');
      expect(controller.items.length, 2);
    });

    test(
      'cancel accepts approved requests and rejects active borrows',
      () async {
        final log = <http.Request>[];
        final controller = makeController();

        expect(
          await run({}, log, () => controller.cancel(1)),
          'Only requests awaiting receipt can be cancelled',
        );
        expect(
          await run({}, log, () => controller.cancel(99)),
          'Borrow not found',
        );
        expect(log, isEmpty);
      },
    );

    test('requestReturn calls PATCH /return then reloads', () async {
      final log = <http.Request>[];
      final controller = makeController();

      final err = await run(
        {
          'PATCH /api/borrows/1/return': json({'message': 'ok'}),
          'GET /api/borrows/my': reload,
        },
        log,
        () => controller.requestReturn(1),
      );

      expect(err, isNull);
      expect(log.first.url.path, '/api/borrows/1/return');
    });

    test('requestReturn only works for borrowed items', () async {
      final controller = makeController();

      expect(
        await run({}, [], () => controller.requestReturn(3)),
        'Borrow is not active',
      );
    });
  });
}
