import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/my_borrowed_items/controller/my_borrowed_controller.dart';

void main() {
  test('load groups borrows and sums held deposits', () async {
    final controller = MyBorrowedController(
      initialItems: const [
        BorrowModel(
            id: 1,
            assetId: 5,
            rentalDays: 2,
            status: 'borrowed',
            paymentStatus: 'paid',
            deposit: 500,
        ),
        BorrowModel(
            id: 2,
            assetId: 6,
            rentalDays: 2,
            status: 'returned_pending',
            paymentStatus: 'paid',
            deposit: 200,
        ),
        BorrowModel(
            id: 3,
            assetId: 7,
            rentalDays: 2,
            status: 'requested',
            paymentStatus: 'unpaid',
            deposit: 100,
        ),
        BorrowModel(
            id: 4,
            assetId: 8,
            rentalDays: 2,
            status: 'returned_confirmed',
            paymentStatus: 'paid',
            deposit: 50,
        ),
      ],
    );

    await controller.load();

    expect(controller.borrowing.map((borrow) => borrow.id), [1, 2]);
    expect(controller.pending.map((borrow) => borrow.id), [3]);
    expect(controller.returned.map((borrow) => borrow.id), [4]);
    expect(controller.heldDeposit, 700);
  });

  test('cancel removes a pending request from the current list', () async {
    final controller = MyBorrowedController(
      initialItems: const [
        BorrowModel(
          id: 3,
          assetId: 7,
          rentalDays: 1,
          status: 'requested',
          paymentStatus: 'unpaid',
        ),
      ],
    );
    await controller.load();

    final error = await controller.cancel(3);

    expect(error, isNull);
    expect(controller.items, isEmpty);
  });

  test('requestReturn marks a borrowed item as returned_pending', () async {
    final controller = MyBorrowedController(
      initialItems: const [
        BorrowModel(
          id: 1,
          assetId: 5,
          rentalDays: 1,
          status: 'borrowed',
          paymentStatus: 'paid',
        ),
      ],
    );
    await controller.load();

    final error = await controller.requestReturn(1);

    expect(error, isNull);
    expect(controller.items.single.status, 'returned_pending');
  });
}
