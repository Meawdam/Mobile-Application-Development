import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/requests_returns/controller/requests_returns_controller.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements Authservice {}

void main() {
  MockAuthService makeService() {
    final service = MockAuthService();
    when(() => service.loadToken()).thenAnswer((_) async => 'test-token');
    return service;
  }

  // รันโค้ดโดยให้ http ตอบจาก routes (key = "METHOD /path") แทน server จริง
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

  Map<String, dynamic> record(int id, String status) => {
        'id': id,
        'asset_id': id + 100,
        'asset_name': 'Item $id',
        'borrower_name': 'borrower$id',
        'status': status,
        'payment_status': status == 'requested' ? 'unpaid' : 'paid',
        'rental_days': 1,
        'planned_return_date': '2026-11-20',
      };

  final records = [
    record(1, 'requested'),
    record(2, 'cancelled'),
    record(3, 'borrowed'),
    record(4, 'returned_pending'),
    record(5, 'returned_confirmed'),
    record(6, 'approved'),
  ];

  RequestsReturnsController makeController() => RequestsReturnsController(
        service: makeService(),
        initialItems: records.map(BorrowModel.fromJson).toList(),
      );

  group('sections', () {
    test('Waiting for Response has requests and cancelled requests', () {
      expect(makeController().waitingForResponse.map((b) => b.id), [1, 2]);
    });

    test('Borrowed Items has borrowed and return-pending items', () {
      expect(makeController().borrowedItems.map((b) => b.id), [3, 4]);
    });
  });

  group('load', () {
    test('calls GET /api/borrows/owner with the token and fills items', () async {
      final log = <http.Request>[];
      final controller = RequestsReturnsController(service: makeService());

      await run({
        'GET /api/borrows/owner': json({'data': records}),
      }, log, controller.load);

      expect(log.single.headers['Authorization'], 'Bearer test-token');
      expect(controller.items.length, 6);
      expect(controller.error, isNull);
    });

    test('shows the backend error message', () async {
      final controller = RequestsReturnsController(service: makeService());

      await run({
        'GET /api/borrows/owner': json({'message': 'Invalid or expired token'}, 403),
      }, [], controller.load);

      expect(controller.error, 'Invalid or expired token');
    });

    test('shows Connection error when the server is unreachable', () async {
      final controller = RequestsReturnsController(service: makeService());

      await http.runWithClient(
        controller.load,
        () => MockClient((_) async => throw http.ClientException('down')),
      );

      expect(controller.error, 'Connection error');
    });
  });

  group('actions', () {
    final reload = json({'data': <Object>[]});

    test('approve calls PATCH /approve then reloads', () async {
      final log = <http.Request>[];
      final controller = makeController();

      final err = await run({
        'PATCH /api/borrows/1/approve': json({'message': 'ok'}),
        'GET /api/borrows/owner': reload,
      }, log, () => controller.approve(1));

      expect(err, isNull);
      expect(log.map((r) => '${r.method} ${r.url.path}'), [
        'PATCH /api/borrows/1/approve',
        'GET /api/borrows/owner',
      ]);
    });

    test('approve returns the backend message when it fails', () async {
      final controller = makeController();

      final err = await run({
        'PATCH /api/borrows/1/approve': json(
          {'message': 'Borrow request is no longer awaiting a decision'},
          400,
        ),
      }, [], () => controller.approve(1));

      expect(err, 'Borrow request is no longer awaiting a decision');
    });

    test('approve only works for requests waiting for a response', () async {
      final log = <http.Request>[];
      final controller = makeController();

      expect(await run({}, log, () => controller.approve(3)),
          'Request is no longer waiting for a response');
      expect(await run({}, log, () => controller.approve(99)), 'Borrow not found');
      expect(log, isEmpty);
    });

    test('reject sends the reason in the request body', () async {
      final log = <http.Request>[];
      final controller = makeController();

      final err = await run({
        'PATCH /api/borrows/1/reject': json({'message': 'ok'}),
        'GET /api/borrows/owner': reload,
      }, log, () => controller.reject(1, '  Item is broken  '));

      expect(err, isNull);
      expect(jsonDecode(log.first.body), {'reason': 'Item is broken'});
    });

    test('reject needs a reason and does not call the API without one', () async {
      final log = <http.Request>[];
      final controller = makeController();

      final err = await run({}, log, () => controller.reject(1, '   '));

      expect(err, 'A reason is required to reject a request');
      expect(log, isEmpty);
    });

    test('reject rejects a reason longer than 500 characters', () async {
      final controller = makeController();

      final err = await run({}, [], () => controller.reject(1, 'a' * 501));

      expect(err, 'Reason must not exceed 500 characters');
    });

    test('confirmReturn calls PATCH /confirm-return then reloads', () async {
      final log = <http.Request>[];
      final controller = makeController();

      final err = await run({
        'PATCH /api/borrows/4/confirm-return': json({'message': 'ok'}),
        'GET /api/borrows/owner': reload,
      }, log, () => controller.confirmReturn(4));

      expect(err, isNull);
      expect(log.first.url.path, '/api/borrows/4/confirm-return');
    });

    test('confirmReturn needs a pending return', () async {
      final controller = makeController();

      expect(await run({}, [], () => controller.confirmReturn(3)),
          'Return has not been requested');
    });
  });
}
