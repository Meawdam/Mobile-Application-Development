// ทดสอบ DeleteItemController (ชีตยืนยันลบไอเทม)
// ตรวจการเปิด/ปิดชีต และกฎการลบ:
// ลบได้เฉพาะเจ้าของ และห้ามลบไอเทมที่กำลังถูกยืมอยู่
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/delete_item/controller/delete_item_controller.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:frontend/modules/user/shared/model/lending_item_model.dart';

// สร้างไอเทมตัวอย่าง
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
  late MyLendingController lending;
  late DeleteItemController controller;

  // ก่อนทุกเทส: ผู้ใช้ u1 มีไอเทม 1 (ปกติ) กับ 2 (ถูกยืมอยู่)
  // และมีไอเทม 3 ที่เป็นของคนอื่น
  setUp(() {
    lending = MyLendingController(
      initialItems: [
        makeItem('1'),
        makeItem('2', status: ItemStatus.borrowed),
        makeItem('3', owner: 'other'),
      ],
    );
    controller = DeleteItemController(lending, currentUserId: 'u1');
  });

  test('1. starts closed, and open selects the item', () {
    expect(controller.isOpen, isFalse);

    expect(controller.open('1'), isTrue);
    expect(controller.isOpen, isTrue);
    expect(controller.selectedItem!.id, '1');
  });

  // กดยกเลิก -> ชีตปิด และไอเทมยังอยู่
  test('2. cancel closes the sheet and keeps the item', () {
    controller.open('1');
    controller.cancel();

    expect(controller.isOpen, isFalse);
    expect(lending.findById('1'), isNotNull);
  });

  // กดยืนยัน -> ไอเทมถูกลบ และชีตปิด
  test('3. confirmDelete removes the item and closes the sheet', () {
    controller.open('1');
    final result = controller.confirmDelete();

    expect(result, DeleteItemResult.success);
    expect(lending.findById('1'), isNull);
    expect(controller.isOpen, isFalse);
  });

  test('4. cannot delete an item owned by someone else', () {
    controller.open('3');
    final result = controller.confirmDelete();

    expect(result, DeleteItemResult.forbidden);
    expect(lending.findById('3'), isNotNull);
  });

  test('5. cannot delete an item that is currently borrowed', () {
    controller.open('2');
    final result = controller.confirmDelete();

    expect(result, DeleteItemResult.itemBorrowed);
    expect(lending.findById('2'), isNotNull);
  });

  test('6. open returns false for an item that does not exist', () {
    expect(controller.open('zzz'), isFalse);
    expect(controller.isOpen, isFalse);
  });
}
