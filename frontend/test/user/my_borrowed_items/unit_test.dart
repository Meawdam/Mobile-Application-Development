import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/my_borrowed_items/controller/my_borrowed_controller.dart';

import '../../helpers/test_fakes.dart';

void main() {
  test('1. load groups borrows and sums held deposit', () async {
    final api = FakeBorrowApi(myBorrows: [
      sampleBorrow(id: 1, status: 'borrowed', paymentStatus: 'paid', deposit: 500),
      sampleBorrow(
        id: 2,
        status: 'returned_pending',
        paymentStatus: 'paid',
        deposit: 200,
      ),
      sampleBorrow(
        id: 3,
        status: 'requested',
        paymentStatus: 'unpaid',
        deposit: 100,
      ),
      sampleBorrow(
        id: 4,
        status: 'returned_confirmed',
        paymentStatus: 'paid',
        deposit: 50,
      ),
    ]);
    final controller = MyBorrowedController(borrowApi: api);

    await controller.load();

    expect(controller.borrowing.map((b) => b.id), [1, 2]);
    expect(controller.pending.map((b) => b.id), [3]);
    expect(controller.returned.map((b) => b.id), [4]);
    expect(controller.heldDeposit, 700);
  });

  test('2. cancel removes a request and reloads', () async {
    final api = FakeBorrowApi(myBorrows: [
      sampleBorrow(id: 3, status: 'requested', paymentStatus: 'unpaid'),
    ]);
    final controller = MyBorrowedController(borrowApi: api);
    await controller.load();

    final error = await controller.cancel(3);

    expect(error, isNull);
    expect(api.cancelled, [3]);
    expect(controller.items, isEmpty);
  });

  test('3. requestReturn marks item returned_pending', () async {
    final api = FakeBorrowApi(myBorrows: [
      sampleBorrow(id: 1, status: 'borrowed'),
    ]);
    final controller = MyBorrowedController(borrowApi: api);
    await controller.load();

    final error = await controller.requestReturn(1);

    expect(error, isNull);
    expect(api.returnRequested, [1]);
    expect(controller.items.single.status, 'returned_pending');
  });
}
