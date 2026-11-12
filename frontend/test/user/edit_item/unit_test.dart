// ทดสอบ EditItemController (หน้า Edit Item)
// หน้านี้แก้ได้เฉพาะ ราคา มัดจำ จุดรับ-คืน วันที่คืน
// ชื่อและรายละเอียดแก้ไม่ได้ และไอเทมที่กำลังถูกยืมอยู่ก็แก้ไม่ได้
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/edit_item/controller/edit_item_controller.dart';
import 'package:frontend/modules/user/shared/model/lending_item_model.dart';

void main() {
  // ไอเทมตัวอย่างที่ใช้แก้ไขในทุกเทส
  LendingItem makeItem({ItemStatus status = ItemStatus.ready}) => LendingItem(
    id: '1',
    ownerId: 'u1',
    name: 'Canon Camera',
    description: 'Good condition',
    pricePerDay: 120,
    deposit: 1500,
    pickupPoint: 'Canteen',
    returnBefore: DateTime(2026, 12, 31),
    status: status,
  );

  EditItemController newController({ItemStatus status = ItemStatus.ready}) =>
      EditItemController(
        makeItem(status: status),
        now: () => DateTime(2026, 11, 12),
      );

  // กรอกค่าใหม่ถูกต้อง -> บันทึกสำเร็จ และค่าในไอเทมเปลี่ยนตาม
  test('1. updates price, deposit, pickup point and return date', () {
    final controller = newController();
    final result = controller.save(
      price: '200',
      deposit: '2000',
      pickupPoint: 'Library',
      returnBefore: DateTime(2027, 1, 15),
    );

    expect(result, EditItemResult.success);
    expect(controller.item.pricePerDay, 200);
    expect(controller.item.deposit, 2000);
    expect(controller.item.pickupPoint, 'Library');
    expect(controller.item.returnBefore, DateTime(2027, 1, 15));
  });

  // ชื่อและรายละเอียดต้องเหมือนเดิมหลังบันทึก
  test('2. keeps the name and description unchanged', () {
    final controller = newController();
    controller.save(
      price: '200',
      deposit: '2000',
      pickupPoint: 'Library',
      returnBefore: DateTime(2027, 1, 15),
    );

    expect(controller.item.name, 'Canon Camera');
    expect(controller.item.description, 'Good condition');
  });

  // ราคาไม่ถูกต้อง -> บันทึกไม่ผ่าน และราคาเดิมยังอยู่
  test('3. rejects an invalid price and keeps the old value', () {
    final controller = newController();
    final result = controller.save(
      price: 'abc',
      deposit: '2000',
      pickupPoint: 'Library',
      returnBefore: DateTime(2027, 1, 15),
    );

    expect(result, EditItemResult.validationFailed);
    expect(controller.item.pricePerDay, 120);
  });

  // ไอเทมที่กำลังถูกยืมอยู่ แก้ไม่ได้
  test('4. does not allow editing an item that is currently borrowed', () {
    final controller = newController(status: ItemStatus.borrowed);
    final result = controller.save(
      price: '200',
      deposit: '2000',
      pickupPoint: 'Library',
      returnBefore: DateTime(2027, 1, 15),
    );

    expect(result, EditItemResult.itemBorrowed);
    expect(controller.item.pricePerDay, 120);
  });

  // hasChanges ใช้ดูว่าผู้ใช้แก้ค่าไปจากเดิมหรือยัง (เช่น เปิด/ปิดปุ่ม Save)
  test('5. hasChanges tells whether the values differ from the item', () {
    final controller = newController();
    final sameDate = DateTime(2026, 12, 31);

    expect(
      controller.hasChanges(
        price: '120',
        deposit: '1500',
        pickupPoint: 'Canteen',
        returnBefore: sameDate,
      ),
      isFalse,
    );
    expect(
      controller.hasChanges(
        price: '999',
        deposit: '1500',
        pickupPoint: 'Canteen',
        returnBefore: sameDate,
      ),
      isTrue,
    );
  });
}
