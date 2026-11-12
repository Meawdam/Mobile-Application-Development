import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/requests_returns/controller/requests_returns_controller.dart';

import '../../helpers/test_fakes.dart';

void main() {
  test('1. load splits waiting responses and borrowed items', () async {
    final api = FakeBorrowApi(lending: [
      sampleBorrow(id: 1, status: 'requested', paymentStatus: 'unpaid'),
      sampleBorrow(id: 2, status: 'returned_pending', paymentStatus: 'paid'),
      sampleBorrow(id: 3, status: 'borrowed', paymentStatus: 'paid'),
    ]);
    final controller = RequestsReturnsController(borrowApi: api);

    await controller.load();

    expect(controller.waitingForResponse.map((b) => b.id), [1, 2]);
    expect(controller.borrowedItems.map((b) => b.id), [3]);
  });

  test('2. confirmReturn refreshes lending list', () async {
    final api = FakeBorrowApi(lending: [
      sampleBorrow(id: 2, status: 'returned_pending'),
    ]);
    final controller = RequestsReturnsController(borrowApi: api);
    await controller.load();

    final error = await controller.confirmReturn(2);

    expect(error, isNull);
    expect(api.returnConfirmed, [2]);
    expect(controller.items.single.status, 'returned_confirmed');
  });
}
