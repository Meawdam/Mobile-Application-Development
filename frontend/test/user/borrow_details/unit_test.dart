import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/borrow_details/controller/borrow_details_controller.dart';
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

  Map<String, dynamic> record(String status, String payment) => {
        'id': 12,
        'asset_id': 5,
        'asset_name': 'Camera',
        'owner_name': 'alex',
        'pickup_point': 'Library front desk',
        'rental_days': 2,
        'status': status,
        'payment_status': payment,
      };

  BorrowModel model(String status, String payment) =>
      BorrowModel.fromJson(record(status, payment));

  List<TimelineStepState> timelineOf(String status, String payment) {
    final controller = BorrowDetailsController(service: makeService());
    controller.borrow = model(status, payment);
    return controller.timeline;
  }

  group('load', () {
    test('calls GET /api/borrows/{id} with the token', () async {
      final log = <http.Request>[];
      final controller = BorrowDetailsController(service: makeService());

      await run({
        'GET /api/borrows/12': json({'data': record('borrowed', 'paid')}),
      }, log, () => controller.load(12));

      expect(log.single.headers['Authorization'], 'Bearer test-token');
      expect(controller.borrow?.id, 12);
      expect(controller.borrow?.ownerName, 'alex');
      expect(controller.error, isNull);
    });

    test('shows the backend error message', () async {
      final controller = BorrowDetailsController(service: makeService());

      await run({
        'GET /api/borrows/12': json({'message': 'Borrow record not found'}, 404),
      }, [], () => controller.load(12));

      expect(controller.borrow, isNull);
      expect(controller.error, 'Borrow record not found');
    });

    test('shows Connection error when the server is unreachable', () async {
      final controller = BorrowDetailsController(service: makeService());

      await http.runWithClient(
        () => controller.load(12),
        () => MockClient((_) async => throw http.ClientException('down')),
      );

      expect(controller.error, 'Connection error');
    });
  });

  group('timeline', () {
    test('unpaid request: Paid is in progress (yellow)', () {
      expect(timelineOf('requested', 'unpaid'), [
        TimelineStepState.inProgress,
        TimelineStepState.notStarted,
        TimelineStepState.notStarted,
        TimelineStepState.notStarted,
      ]);
    });

    test('paid but not received: Received is in progress (yellow)', () {
      expect(timelineOf('approved', 'paid'), [
        TimelineStepState.done,
        TimelineStepState.inProgress,
        TimelineStepState.notStarted,
        TimelineStepState.notStarted,
      ]);
    });

    test('received: Borrowed is in progress', () {
      expect(timelineOf('borrowed', 'paid'), [
        TimelineStepState.done,
        TimelineStepState.done,
        TimelineStepState.inProgress,
        TimelineStepState.notStarted,
      ]);
    });

    test('return pending: Returned is in progress', () {
      expect(timelineOf('returned_pending', 'paid'), [
        TimelineStepState.done,
        TimelineStepState.done,
        TimelineStepState.done,
        TimelineStepState.inProgress,
      ]);
    });

    test('returned: every step is done (green)', () {
      expect(
        timelineOf('returned_confirmed', 'refunded')
            .every((s) => s == TimelineStepState.done),
        isTrue,
      );
    });

    test('cancelled request: nothing started', () {
      expect(
        timelineOf('cancelled', 'unpaid')
            .every((s) => s == TimelineStepState.notStarted),
        isTrue,
      );
    });
  });

  group('actions', () {
    BorrowDetailsController makeController(String status, String payment) {
      final controller = BorrowDetailsController(service: makeService());
      controller.borrow = model(status, payment);
      return controller;
    }

    test('canConfirmReceived only when paid and approved by the owner', () {
      expect(makeController('approved', 'paid').canConfirmReceived, isTrue);
      // ยังไม่ approve = ยังไม่แสดงปุ่ม Received
      expect(makeController('requested', 'paid').canConfirmReceived, isFalse);
      expect(makeController('approved', 'unpaid').canConfirmReceived, isFalse);
      expect(makeController('borrowed', 'paid').canConfirmReceived, isFalse);
    });

    test('confirmReceived calls PATCH /confirm-received then reloads', () async {
      final log = <http.Request>[];
      final controller = makeController('approved', 'paid');

      final err = await run({
        'PATCH /api/borrows/12/confirm-received': json({'message': 'ok'}),
        'GET /api/borrows/12': json({'data': record('borrowed', 'paid')}),
      }, log, controller.confirmReceived);

      expect(err, isNull);
      expect(log.map((r) => '${r.method} ${r.url.path}'), [
        'PATCH /api/borrows/12/confirm-received',
        'GET /api/borrows/12',
      ]);
      expect(controller.borrow?.status, 'borrowed');
      expect(controller.canConfirmReceived, isFalse);
    });

    test('confirmReceived is blocked before payment without calling the API', () async {
      final log = <http.Request>[];
      final controller = makeController('requested', 'unpaid');

      final err = await run({}, log, controller.confirmReceived);

      expect(err, 'Pay for this borrow before confirming receipt');
      expect(log, isEmpty);
    });

    test('confirmReceived returns the backend message when it fails', () async {
      final controller = makeController('approved', 'paid');

      final err = await run({
        'PATCH /api/borrows/12/confirm-received': json(
          {'message': 'Forbidden: You are not the borrower of this item'},
          403,
        ),
      }, [], controller.confirmReceived);

      expect(err, 'Forbidden: You are not the borrower of this item');
    });

    test('requestReturn calls PATCH /return then reloads', () async {
      final log = <http.Request>[];
      final controller = makeController('borrowed', 'paid');

      final err = await run({
        'PATCH /api/borrows/12/return': json({'message': 'ok'}),
        'GET /api/borrows/12': json({'data': record('returned_pending', 'paid')}),
      }, log, controller.requestReturn);

      expect(err, isNull);
      expect(controller.borrow?.status, 'returned_pending');
    });

    test('requestReturn only works for borrowed items', () async {
      final controller = makeController('approved', 'paid');

      expect(await run({}, [], controller.requestReturn), 'Borrow is not active');
    });

    test('confirmReturn calls PATCH /confirm-return then reloads', () async {
      final controller = makeController('returned_pending', 'paid');

      final err = await run({
        'PATCH /api/borrows/12/confirm-return': json({'message': 'ok'}),
        'GET /api/borrows/12': json({'data': record('returned_confirmed', 'refunded')}),
      }, [], controller.confirmReturn);

      expect(err, isNull);
      expect(controller.borrow?.status, 'returned_confirmed');
    });

    test('confirmReturn needs a pending return', () async {
      final controller = makeController('borrowed', 'paid');

      expect(await run({}, [], controller.confirmReturn),
          'Return has not been requested');
    });

    test('actions need a loaded borrow', () async {
      final controller = BorrowDetailsController(service: makeService());

      expect(await controller.confirmReceived(), 'Missing borrow');
      expect(await controller.requestReturn(), 'Missing borrow');
      expect(await controller.confirmReturn(), 'Missing borrow');
    });
  });
}
