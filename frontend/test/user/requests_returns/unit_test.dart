import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/requests_returns/controller/requests_returns_controller.dart';

void main() {
  test('load separates waiting responses from borrowed items', () async {
    final controller = RequestsReturnsController(
      initialItems: const [
        BorrowModel(
            id: 1,
            assetId: 5,
            rentalDays: 1,
            status: 'requested',
            paymentStatus: 'unpaid',
        ),
        BorrowModel(
            id: 2,
            assetId: 6,
            rentalDays: 1,
            status: 'returned_pending',
            paymentStatus: 'paid',
        ),
        BorrowModel(
            id: 3,
            assetId: 7,
            rentalDays: 1,
            status: 'borrowed',
            paymentStatus: 'paid',
        ),
      ],
    );

    await controller.load();

    expect(controller.waitingForResponse.map((borrow) => borrow.id), [1, 2]);
    expect(controller.borrowedItems.map((borrow) => borrow.id), [3]);
  });

  test('confirmReturn updates the local borrow status', () async {
    final controller = RequestsReturnsController(
      initialItems: [
        const BorrowModel(
          id: 2,
          assetId: 6,
          rentalDays: 1,
          status: 'returned_pending',
          paymentStatus: 'paid',
        ),
      ],
    );
    await controller.load();

    final error = await controller.confirmReturn(2);

    expect(error, isNull);
    expect(controller.items.single.status, 'returned_confirmed');
  });
}
