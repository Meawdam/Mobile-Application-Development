// ทดสอบ DeleteItemController (ชีตยืนยันลบไอเทม)
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/delete_item/controller/delete_item_controller.dart';
import 'package:frontend/modules/user/shared/model/lending_item_model.dart';

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

void main() {
  late DeleteItemController controller;

  setUp(() {
    controller = DeleteItemController(
      currentUserId: 'u1',
      initialItems: [
        makeItem('1'),
        makeItem('2', status: ItemStatus.borrowed),
        makeItem('3', owner: 'other'),
      ],
    );
  });

  test('1. starts closed, and open selects the item', () {
    expect(controller.isOpen, isFalse);

    expect(controller.open('1'), isTrue);
    expect(controller.isOpen, isTrue);
    expect(controller.selectedItem!.id, '1');
  });

  test('2. cancel closes the sheet and keeps the item', () {
    controller.open('1');
    controller.cancel();

    expect(controller.isOpen, isFalse);
    expect(controller.findById('1'), isNotNull);
  });

  test('3. confirmDelete removes the item and closes the sheet', () {
    controller.open('1');
    final result = controller.confirmDelete();

    expect(result, DeleteItemResult.success);
    expect(controller.findById('1'), isNull);
    expect(controller.isOpen, isFalse);
  });

  test('4. cannot delete an item owned by someone else', () {
    controller.open('3');
    final result = controller.confirmDelete();

    expect(result, DeleteItemResult.forbidden);
    expect(controller.findById('3'), isNotNull);
  });

  test('5. cannot delete an item that is currently borrowed', () {
    controller.open('2');
    final result = controller.confirmDelete();

    expect(result, DeleteItemResult.itemBorrowed);
    expect(controller.findById('2'), isNotNull);
  });

  test('6. open returns false for an item that does not exist', () {
    expect(controller.open('zzz'), isFalse);
    expect(controller.isOpen, isFalse);
  });
}
