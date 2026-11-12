// ทดสอบ LendingItem (model) และ MyLendingController (หน้า My Lending)
// ตรวจการแปลงข้อมูลจาก backend และการเพิ่ม/แก้/ลบ/นับไอเทม
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:frontend/modules/user/shared/model/lending_item_model.dart';

// สร้างไอเทมตัวอย่าง
LendingItem makeItem(
  String id, {
  ItemStatus status = ItemStatus.ready,
  ApprovalStatus approval = ApprovalStatus.approved,
}) {
  return LendingItem(
    id: id,
    ownerId: 'u1',
    name: 'Item $id',
    pricePerDay: 100,
    pickupPoint: 'Canteen',
    returnBefore: DateTime(2030, 1, 31),
    status: status,
    approval: approval,
  );
}

void main() {
  // model: แปลง Map ที่ backend ส่งมา (ชื่อฟิลด์แบบ snake_case) เป็น LendingItem
  test('1. LendingItem.fromMap converts backend data correctly', () {
    final item = LendingItem.fromMap({
      'id': 7,
      'owner_id': 3,
      'name': 'Canon Camera',
      'price': 120,
      'down_payment': '1500.00',
      'pickup_point': 'Building 3',
      'return_before': '2030-05-09',
      'status': 'borrowed',
      'approval': 'not approve',
    });

    expect(item.id, '7');
    expect(item.pricePerDay, 120);
    expect(item.deposit, 1500);
    expect(item.returnBefore, DateTime(2030, 5, 9));
    expect(item.status, ItemStatus.borrowed);
    expect(item.approval, ApprovalStatus.notApproved);
  });

  test('2. starts with an empty list', () {
    final controller = MyLendingController();

    expect(controller.isEmpty, isTrue);
    expect(controller.totalCount, 0);
  });

  // เพิ่มไอเทมได้ แต่ id ซ้ำไม่ได้
  test('3. addItem adds an item but rejects a duplicate id', () {
    final controller = MyLendingController();

    expect(controller.addItem(makeItem('1')), isTrue);
    expect(controller.addItem(makeItem('1')), isFalse);
    expect(controller.totalCount, 1);
  });

  test('4. updateItem changes an existing item, false if not found', () {
    final controller = MyLendingController(initialItems: [makeItem('1')]);

    expect(
      controller.updateItem(makeItem('1').copyWith(name: 'New name')),
      isTrue,
    );
    expect(controller.findById('1')!.name, 'New name');
    expect(controller.updateItem(makeItem('zzz')), isFalse);
  });

  test('5. removeItem deletes an item, false if not found', () {
    final controller = MyLendingController(initialItems: [makeItem('1')]);

    expect(controller.removeItem('1'), isTrue);
    expect(controller.totalCount, 0);
    expect(controller.removeItem('1'), isFalse);
  });

  // นับไอเทมทั้งหมด / ที่กำลังถูกยืม / ที่รอแอดมินอนุมัติ
  test('6. counts borrowed items and items waiting for approval', () {
    final controller = MyLendingController(
      initialItems: [
        makeItem('1'),
        makeItem('2', status: ItemStatus.borrowed),
        makeItem('3', approval: ApprovalStatus.pending),
      ],
    );

    expect(controller.totalCount, 3);
    expect(controller.borrowedCount, 1);
    expect(controller.waitingApprovalCount, 1);
  });
}
