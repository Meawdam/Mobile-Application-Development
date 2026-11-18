import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/requests_returns/controller/requests_returns_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_helpers.dart';

RequestsReturnsController makeController(MockClient client) =>
    RequestsReturnsController(client: client, authService: FakeAuthservice());

void main() {
  test('load calls GET /api/borrows/lending and separates the lists', () async {
    late http.Request captured;
    final controller = makeController(
      MockClient((request) async {
        captured = request;
        return jsonResponse({
          'data': [
            borrowJson(id: 1, status: 'requested', paymentStatus: 'unpaid'),
            borrowJson(id: 2, status: 'returned_pending'),
            borrowJson(id: 3, status: 'borrowed'),
          ],
        });
      }),
    );

    await controller.load();

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/borrows/lending');
    expect(captured.headers['Authorization'], 'Bearer test-token');
    expect(controller.waitingForResponse.map((b) => b.id), [1, 2]);
    expect(controller.borrowedItems.map((b) => b.id), [3]);
  });

  test('load shows the backend message on failure', () async {
    final controller = makeController(
      MockClient((request) async => jsonResponse({'message': 'Invalid token'}, 403)),
    );

    await controller.load();

    expect(controller.error, 'Invalid token');
  });

  test('confirmReturn calls PATCH and updates the local status', () async {
    late http.Request patch;
    final controller = makeController(
      MockClient((request) async {
        if (request.method == 'PATCH') {
          patch = request;
          return jsonResponse({'message': 'Return confirmed'});
        }
        return jsonResponse({
          'data': [borrowJson(id: 2, status: 'returned_pending')],
        });
      }),
    );
    await controller.load();

    final error = await controller.confirmReturn(2);

    expect(error, isNull);
    expect(patch.url.path, '/api/borrows/2/confirm-return');
    expect(controller.items.single.status, 'returned_confirmed');
  });

  test('confirmReturn returns the backend message on failure', () async {
    final controller = makeController(
      MockClient((request) async {
        if (request.method == 'PATCH') {
          return jsonResponse(
            {'message': 'The borrower has not requested to return this item'},
            400,
          );
        }
        return jsonResponse({
          'data': [borrowJson(id: 2, status: 'returned_pending')],
        });
      }),
    );
    await controller.load();

    final error = await controller.confirmReturn(2);

    expect(error, 'The borrower has not requested to return this item');
    expect(controller.items.single.status, 'returned_pending');
  });

  test('confirmReturn rejects unknown or non-pending borrows locally', () async {
    final controller = makeController(
      MockClient((request) async {
        return jsonResponse({
          'data': [borrowJson(id: 3, status: 'borrowed')],
        });
      }),
    );
    await controller.load();

    expect(await controller.confirmReturn(99), 'Borrow not found');
    expect(await controller.confirmReturn(3), 'Return has not been requested');
  });
}
