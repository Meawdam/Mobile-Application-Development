// ทดสอบ ConfirmReturnController (เจ้าของกดยืนยันว่าได้ของคืนแล้ว)
// เรียก GET /api/borrows/lending และ PATCH /api/borrows/:id/confirm-return
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/confirm_return/controller/confirm_return_controller.dart';
import 'package:frontend/modules/user/shared/model/lending_item_model.dart';
import 'package:frontend/modules/user/shared/model/return_request_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_helpers.dart';

ReturnRequest makeRequest(
  String id, {
  String owner = 'u1',
  BorrowStatus status = BorrowStatus.returnedPending,
}) {
  return ReturnRequest(
    id: id,
    assetId: 'a1',
    assetName: 'Item a1',
    ownerId: owner,
    borrowerName: 'Somchai',
    status: status,
  );
}

ConfirmReturnController makeController(MockClient client) {
  return ConfirmReturnController(
    [
      makeRequest('1'),
      makeRequest('2', status: BorrowStatus.borrowed),
      makeRequest('3', status: BorrowStatus.returnedConfirmed),
      makeRequest('4', owner: 'other'),
    ],
    currentUserId: 'u1',
    lendingItems: [
      LendingItem(
        id: 'a1',
        ownerId: 'u1',
        name: 'Item a1',
        pricePerDay: 100,
        pickupPoint: 'Canteen',
        returnBefore: DateTime(2030, 1, 1),
        status: ItemStatus.borrowed,
      ),
    ],
    client: client,
    authService: FakeAuthservice(),
  );
}

MockClient okClient() => MockClient(
  (request) async => jsonResponse({'message': 'Return confirmed'}),
);

void main() {
  test('1. lists only my requests that are waiting for confirmation', () {
    final controller = makeController(okClient());
    expect(controller.awaitingCount, 1);
    expect(controller.awaitingConfirmation.single.id, '1');
  });

  test('2. confirming calls PATCH confirm-return and frees the item', () async {
    late http.Request captured;
    final controller = makeController(
      MockClient((request) async {
        captured = request;
        return jsonResponse({'message': 'Return confirmed'});
      }),
    );

    final result = await controller.confirmReturn('1');

    expect(result, ConfirmReturnResult.success);
    expect(captured.method, 'PATCH');
    expect(captured.url.path, '/api/borrows/1/confirm-return');
    expect(captured.headers['Authorization'], 'Bearer test-token');
    expect(controller.awaitingCount, 0);
    expect(
      controller.lendingItems.singleWhere((i) => i.id == 'a1').status,
      ItemStatus.ready,
    );
  });

  test('3. only the owner can confirm', () async {
    final controller = makeController(okClient());
    expect(await controller.confirmReturn('4'), ConfirmReturnResult.forbidden);
  });

  test('4. cannot confirm when the borrower has not requested a return', () async {
    final controller = makeController(okClient());
    expect(await controller.confirmReturn('2'), ConfirmReturnResult.notRequested);
  });

  test('5. cannot confirm a return twice', () async {
    final controller = makeController(okClient());
    expect(
      await controller.confirmReturn('3'),
      ConfirmReturnResult.alreadyConfirmed,
    );
  });

  test('6. returns notFound for an unknown request', () async {
    final controller = makeController(okClient());
    expect(await controller.confirmReturn('zzz'), ConfirmReturnResult.notFound);
  });

  test('7. backend 400 "already returned" maps to alreadyConfirmed', () async {
    final controller = makeController(
      MockClient(
        (request) async =>
            jsonResponse({'message': 'This item has already been returned'}, 400),
      ),
    );

    expect(
      await controller.confirmReturn('1'),
      ConfirmReturnResult.alreadyConfirmed,
    );
    expect(controller.awaitingCount, 1);
  });

  test('8. backend 403 maps to forbidden and keeps the status', () async {
    final controller = makeController(
      MockClient((request) async => jsonResponse({'message': 'Forbidden'}, 403)),
    );

    expect(await controller.confirmReturn('1'), ConfirmReturnResult.forbidden);
    expect(controller.awaitingCount, 1);
  });

  test('9. a connection error is failed', () async {
    final controller = makeController(
      MockClient((request) async => throw http.ClientException('offline')),
    );

    expect(await controller.confirmReturn('1'), ConfirmReturnResult.failed);
    expect(controller.error, 'Connection error');
  });

  test('10. load maps GET /api/borrows/lending into my requests', () async {
    late http.Request captured;
    final controller = makeController(
      MockClient((request) async {
        captured = request;
        return jsonResponse({
          'data': [
            borrowJson(id: 7, status: 'returned_pending'),
            borrowJson(id: 8, status: 'borrowed'),
          ],
        });
      }),
    );

    await controller.load();

    expect(captured.url.path, '/api/borrows/lending');
    expect(controller.requests.map((r) => r.id), ['7', '8']);
    expect(controller.awaitingCount, 1);
    expect(controller.awaitingConfirmation.single.id, '7');
    expect(controller.error, isNull);
  });
}
