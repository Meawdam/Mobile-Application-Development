// ทดสอบ AddItemController (หน้า Add Item)
// ตรวจว่ากรอกฟอร์มแล้ว: ถ้าข้อมูลถูกต้องจะสร้างไอเทมสถานะรออนุมัติ
// ถ้าข้อมูลผิดจะไม่สร้างไอเทม และบอก error ของช่องที่ผิด
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/add_item/controller/add_item_controller.dart';
import 'package:frontend/modules/user/shared/model/lending_item_model.dart';

void main() {
  // กำหนด "วันนี้" เองให้เทสได้ผลเหมือนเดิมทุกวัน
  final today = DateTime(2026, 11, 12);
  final tomorrow = DateTime(2026, 11, 13);

  AddItemController newController() =>
      AddItemController(ownerId: 'u1', now: () => today);

  // กรอกถูกทุกช่อง -> ได้ไอเทมใหม่ที่ยังรอแอดมินอนุมัติ
  test('1. creates an item pending admin approval when the form is valid', () {
    final item = newController().submit(
      name: 'Canon Camera',
      price: '120',
      deposit: '1500',
      pickupPoint: 'Canteen',
      returnBefore: tomorrow,
    );

    expect(item, isNotNull);
    expect(item!.name, 'Canon Camera');
    expect(item.pricePerDay, 120);
    expect(item.deposit, 1500);
    expect(item.approval, ApprovalStatus.pending);
  });

  // ชื่อเป็นช่องว่างล้วน -> ไม่ผ่าน
  test('2. rejects an empty item name', () {
    final controller = newController();
    final item = controller.submit(
      name: '   ',
      price: '120',
      pickupPoint: 'Canteen',
      returnBefore: tomorrow,
    );

    expect(item, isNull);
    expect(controller.errors.containsKey('name'), isTrue);
  });

  // ราคาต้องเป็นจำนวนเต็มไม่ติดลบ (ติดลบ ทศนิยม ตัวอักษร ว่าง -> ไม่ผ่าน)
  test('3. rejects a negative, decimal, non-numeric or empty price', () {
    final controller = newController();

    for (final price in ['-5', '12.5', 'abc', '']) {
      final item = controller.submit(
        name: 'Camera',
        price: price,
        pickupPoint: 'Canteen',
        returnBefore: tomorrow,
      );
      expect(item, isNull);
    }
    expect(controller.errors.containsKey('price'), isTrue);
  });

  // มัดจำไม่บังคับกรอก ถ้าเว้นว่างให้เป็น 0
  test('4. treats an empty deposit as 0', () {
    final item = newController().submit(
      name: 'Camera',
      price: '120',
      deposit: '',
      pickupPoint: 'Canteen',
      returnBefore: tomorrow,
    );

    expect(item!.deposit, 0);
  });

  // จุดรับ-คืนต้องกรอก
  test('5. rejects an empty pickup location', () {
    final controller = newController();
    final item = controller.submit(
      name: 'Camera',
      price: '120',
      pickupPoint: '',
      returnBefore: tomorrow,
    );

    expect(item, isNull);
    expect(controller.errors.containsKey('pickupPoint'), isTrue);
  });

  // วันที่ต้องเป็นวันนี้หรืออนาคต (เมื่อวานไม่ผ่าน วันนี้ผ่าน)
  test('6. rejects a past date but accepts today', () {
    final controller = newController();

    final past = controller.submit(
      name: 'Camera',
      price: '120',
      pickupPoint: 'Canteen',
      returnBefore: DateTime(2026, 11, 11),
    );
    expect(past, isNull);
    expect(controller.errors.containsKey('returnBefore'), isTrue);

    final todayItem = controller.submit(
      name: 'Camera',
      price: '120',
      pickupPoint: 'Canteen',
      returnBefore: today,
    );
    expect(todayItem, isNotNull);
  });
}
