import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/borrow_request/controller/borrow_request_controller.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/date_utils.dart';
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

  Map<String, dynamic> asset({String status = 'ready', String approval = 'approved'}) => {
        'id': 4,
        'owner_id': 9,
        'owner_username': 'alex',
        'name': 'Camera',
        'description': 'Mirrorless camera',
        'status': status,
        'approval': approval,
        'down_payment': 200,
        'price': 100,
        'pickup_point': 'Library front desk',
        'return_before': '2099-12-31',
      };

  final today = AppDateUtils.today();

  // โหลดสินค้าแล้วเลือกวัน: รับวันนี้ คืนอีก 2 วัน (รวม 3 วัน)
  Future<BorrowRequestController> loadedController() async {
    final controller = BorrowRequestController(service: makeService());
    await run({'GET /api/assets/4': json({'data': asset()})}, [], () => controller.load(4));
    controller.setPickupDate(today);
    controller.setReturnDate(today.add(const Duration(days: 2)));
    return controller;
  }

  group('load', () {
    test('calls GET /api/assets/{id} with the token', () async {
      final log = <http.Request>[];
      final controller = BorrowRequestController(service: makeService());

      await run({'GET /api/assets/4': json({'data': asset()})}, log, () => controller.load(4));

      expect(log.single.headers['Authorization'], 'Bearer test-token');
      expect(controller.asset?.name, 'Camera');
      expect(controller.asset?.ownerUsername, 'alex');
      expect(controller.error, isNull);
      expect(controller.loading, isFalse);
    });

    test('shows the backend error message', () async {
      final controller = BorrowRequestController(service: makeService());

      await run({
        'GET /api/assets/4': json({'message': 'Asset not found'}, 404),
      }, [], () => controller.load(4));

      expect(controller.asset, isNull);
      expect(controller.error, 'Asset not found');
    });

    test('reports an item that is not available for borrowing', () async {
      final controller = BorrowRequestController(service: makeService());

      await run({
        'GET /api/assets/4': json({'data': asset(status: 'borrowed')}),
      }, [], () => controller.load(4));

      expect(controller.error, 'Item is not available for borrowing');
    });

    test('shows Connection error when the server is unreachable', () async {
      final controller = BorrowRequestController(service: makeService());

      await http.runWithClient(
        () => controller.load(4),
        () => MockClient((_) async => throw http.ClientException('down')),
      );

      expect(controller.error, 'Connection error');
    });
  });

  group('dates and price', () {
    test('rental days, subtotal and total are calculated from the asset', () async {
      final controller = await loadedController();

      expect(controller.datesValid, isTrue);
      expect(controller.rentalDayCount, 3);
      expect(controller.rentalSubtotal, 300);
      expect(controller.deposit, 200);
      expect(controller.total, 500);
    });

    test('return date cannot be before the pickup date', () async {
      final controller = await loadedController();

      controller.setReturnDate(today.subtract(const Duration(days: 1)));

      expect(controller.returnDate, today.add(const Duration(days: 2)));
    });

    test('dates are not valid until both are chosen', () async {
      final controller = BorrowRequestController(service: makeService());
      await run({'GET /api/assets/4': json({'data': asset()})}, [], () => controller.load(4));

      controller.setPickupDate(today);

      expect(controller.datesValid, isFalse);
    });
  });

  group('submitRequest', () {
    test('calls POST /api/borrows and returns the created borrow', () async {
      final log = <http.Request>[];
      final controller = await loadedController();

      final borrow = await run({
        'POST /api/borrows': json({
          'message': 'Borrow request submitted successfully',
          'data': {
            'id': 12,
            'asset_id': 4,
            'pickup_date': AppDateUtils.formatYmd(today),
            'planned_return_date':
                AppDateUtils.formatYmd(today.add(const Duration(days: 2))),
            'rental_days': 3,
            'rental_amount': 300,
            'deposit_amount': 200,
            'total_amount': 500,
            'status': 'requested',
            'payment_status': 'unpaid',
          },
        }, 201),
      }, log, controller.submitRequest);

      expect(jsonDecode(log.single.body), {
        'asset_id': 4,
        'pickup_date': AppDateUtils.formatYmd(today),
        'return_date': AppDateUtils.formatYmd(today.add(const Duration(days: 2))),
      });
      expect(log.single.headers['Authorization'], 'Bearer test-token');
      expect(borrow?.id, 12);
      expect(borrow?.assetName, 'Camera');
      expect(borrow?.totalAmount, 500);
      expect(controller.submitting, isFalse);
    });

    test('shows the backend error message when the request fails', () async {
      final controller = await loadedController();

      final borrow = await run({
        'POST /api/borrows': json({'message': 'Asset is not available for borrowing'}, 400),
      }, [], controller.submitRequest);

      expect(borrow, isNull);
      expect(controller.error, 'Asset is not available for borrowing');
    });

    test('does not call the API before dates are chosen', () async {
      final log = <http.Request>[];
      final controller = BorrowRequestController(service: makeService());

      final borrow = await run({}, log, controller.submitRequest);

      expect(borrow, isNull);
      expect(log, isEmpty);
      expect(controller.error, isNotNull);
    });
  });
}
