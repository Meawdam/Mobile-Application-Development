// ทดสอบ DeleteItemController (ชีตยืนยันลบไอเทม) ที่เรียก DELETE /api/assets/:id
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/delete_item/controller/delete_item_controller.dart';
import 'package:frontend/modules/user/shared/model/lending_item_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_helpers.dart';

LendingItem makeItem(
  String id, {
  String owner = 'u1',
  ItemStatus status = ItemStatus.ready,
}) {
  return LendingItem(
    id: id,
    ownerId: owner,
    name: 'Item $id',
    pricePerDay: 100,
    pickupPoint: 'Canteen',
    returnBefore: DateTime(2030, 1, 1),
    status: status,
  );
}

DeleteItemController makeController(
  MockClient client, {
  FakeAuthservice? auth,
}) {
  return DeleteItemController(
    currentUserId: 'u1',
    initialItems: [
      makeItem('1'),
      makeItem('2', status: ItemStatus.borrowed),
      makeItem('3', owner: 'other'),
    ],
    client: client,
    authService: auth ?? FakeAuthservice(),
  );
}

MockClient okClient() => MockClient(
  (request) async => jsonResponse({'message': 'Asset deleted successfully'}),
);

void main() {
  test('1. starts closed, and open selects the item', () {
    final controller = makeController(okClient());
    expect(controller.isOpen, isFalse);

    expect(controller.open('1'), isTrue);
    expect(controller.isOpen, isTrue);
    expect(controller.selectedItem!.id, '1');
  });

  test('2. cancel closes the sheet and keeps the item', () {
    final controller = makeController(okClient());
    controller.open('1');
    controller.cancel();

    expect(controller.isOpen, isFalse);
    expect(controller.findById('1'), isNotNull);
  });

  test('3. confirmDelete calls DELETE, removes the item and closes the sheet', () async {
    late http.Request captured;
    final controller = makeController(
      MockClient((request) async {
        captured = request;
        return jsonResponse({'message': 'Asset deleted successfully'});
      }),
    );
    controller.open('1');

    final result = await controller.confirmDelete();

    expect(result, DeleteItemResult.success);
    expect(captured.method, 'DELETE');
    expect(captured.url.path, '/api/assets/1');
    expect(captured.headers['Authorization'], 'Bearer test-token');
    expect(controller.findById('1'), isNull);
    expect(controller.isOpen, isFalse);
  });

  test('4. cannot delete an item owned by someone else (no API call)', () async {
    var called = false;
    final controller = makeController(
      MockClient((request) async {
        called = true;
        return jsonResponse({});
      }),
    );
    controller.open('3');

    final result = await controller.confirmDelete();

    expect(result, DeleteItemResult.forbidden);
    expect(controller.findById('3'), isNotNull);
    expect(called, isFalse);
  });

  test('5. cannot delete an item that is currently borrowed (no API call)', () async {
    var called = false;
    final controller = makeController(
      MockClient((request) async {
        called = true;
        return jsonResponse({});
      }),
    );
    controller.open('2');

    final result = await controller.confirmDelete();

    expect(result, DeleteItemResult.itemBorrowed);
    expect(controller.findById('2'), isNotNull);
    expect(called, isFalse);
  });

  test('6. open returns false for an item that does not exist', () {
    final controller = makeController(okClient());
    expect(controller.open('zzz'), isFalse);
    expect(controller.isOpen, isFalse);
  });

  test('7. a 409 from the backend maps to itemBorrowed and keeps the item', () async {
    final controller = makeController(
      MockClient(
        (request) async => jsonResponse({'message': 'Asset has borrow history'}, 409),
      ),
    );
    controller.open('1');

    final result = await controller.confirmDelete();

    expect(result, DeleteItemResult.itemBorrowed);
    expect(controller.findById('1'), isNotNull);
  });

  test('8. a 404 from the backend maps to notFound', () async {
    final controller = makeController(
      MockClient((request) async => jsonResponse({'message': 'Asset not found'}, 404)),
    );
    controller.open('1');

    expect(await controller.confirmDelete(), DeleteItemResult.notFound);
  });

  test('9. a server error is failed and exposes the message', () async {
    final controller = makeController(
      MockClient((request) async => jsonResponse({'message': 'Internal Server Error'}, 500)),
    );
    controller.open('1');

    expect(await controller.confirmDelete(), DeleteItemResult.failed);
    expect(controller.error, 'Internal Server Error');
    expect(controller.findById('1'), isNotNull);
  });

  test('10. a connection error is failed', () async {
    final controller = makeController(
      MockClient((request) async => throw http.ClientException('offline')),
    );
    controller.open('1');

    expect(await controller.confirmDelete(), DeleteItemResult.failed);
    expect(controller.error, 'Connection error');
  });
}
