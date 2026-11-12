// ทดสอบ ConfirmReturnController (เจ้าของกดยืนยันว่าได้ของคืนแล้ว)
// กฎ: ต้องเป็นเจ้าของ และผู้ยืมต้องแจ้งคืนมาก่อน (returnedPending)
// เมื่อยืนยันแล้ว ไอเทมจะกลับมาพร้อมให้ยืมอีกครั้ง
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/confirm_return/controller/confirm_return_controller.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:frontend/modules/user/shared/model/lending_item_model.dart';
import 'package:frontend/modules/user/shared/model/return_request_model.dart';

// สร้างคำขอคืนตัวอย่าง (ค่าเริ่มต้น = ผู้ยืมแจ้งคืนแล้ว รอเจ้าของยืนยัน)
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

void main() {
  late MyLendingController lending;
  late ConfirmReturnController controller;

  // ก่อนทุกเทส: u1 มีไอเทม a1 ที่กำลังถูกยืม และมีคำขอ 4 แบบ
  // 1 = รอยืนยัน, 2 = ยังไม่แจ้งคืน, 3 = ยืนยันแล้ว, 4 = ของคนอื่น
  setUp(() {
    lending = MyLendingController(
      initialItems: [
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
    );
    controller = ConfirmReturnController(
      [
        makeRequest('1'),
        makeRequest('2', status: BorrowStatus.borrowed),
        makeRequest('3', status: BorrowStatus.returnedConfirmed),
        makeRequest('4', owner: 'other'),
      ],
      currentUserId: 'u1',
      lending: lending,
    );
  });

  test('1. lists only my requests that are waiting for confirmation', () {
    expect(controller.awaitingCount, 1);
    expect(controller.awaitingConfirmation.single.id, '1');
  });

  test('2. confirming a return makes the item ready to borrow again', () {
    final result = controller.confirmReturn('1');

    expect(result, ConfirmReturnResult.success);
    expect(controller.awaitingCount, 0);
    expect(lending.findById('a1')!.status, ItemStatus.ready);
  });

  test('3. only the owner can confirm', () {
    expect(controller.confirmReturn('4'), ConfirmReturnResult.forbidden);
  });

  test('4. cannot confirm when the borrower has not requested a return', () {
    expect(controller.confirmReturn('2'), ConfirmReturnResult.notRequested);
  });

  test('5. cannot confirm a return twice', () {
    expect(controller.confirmReturn('3'), ConfirmReturnResult.alreadyConfirmed);
  });

  test('6. returns notFound for an unknown request', () {
    expect(controller.confirmReturn('zzz'), ConfirmReturnResult.notFound);
  });
}
