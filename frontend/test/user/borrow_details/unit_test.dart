import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/borrow_details/controller/borrow_details_controller.dart';

void main() {
  const borrow = BorrowModel(
    id: 12,
    assetId: 5,
    assetName: 'Camera',
    rentalDays: 2,
    status: 'borrowed',
    paymentStatus: 'paid',
  );

  test('load reads borrow details from the provided list', () async {
    final controller = BorrowDetailsController(
      borrows: [borrow],
    );

    await controller.load(12);

    expect(controller.borrow?.id, 12);
    expect(controller.borrow?.status, 'borrowed');
    expect(controller.error, isNull);
  });

  test('requestReturn updates the local borrow status', () async {
    final borrows = [borrow];
    final controller = BorrowDetailsController(borrows: borrows);
    await controller.load(12);

    final error = await controller.requestReturn();

    expect(error, isNull);
    expect(borrows.single.status, 'returned_pending');
    expect(controller.borrow?.status, 'returned_pending');
  });

  test('confirmReturn updates a pending return status', () async {
    final pendingBorrow = borrow.copyWith(status: 'returned_pending');
    final borrows = [pendingBorrow];
    final controller = BorrowDetailsController(borrows: borrows);
    await controller.load(12);

    final error = await controller.confirmReturn();

    expect(error, isNull);
    expect(borrows.single.status, 'returned_confirmed');
    expect(controller.borrow?.status, 'returned_confirmed');
  });
}
