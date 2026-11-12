import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/borrow_details/controller/borrow_details_controller.dart';

import '../../helpers/test_fakes.dart';

void main() {
  test('1. load fetches borrow details', () async {
    final api = FakeBorrowApi(detail: sampleBorrow(id: 12, status: 'borrowed'));
    final controller = BorrowDetailsController(borrowApi: api);

    await controller.load(12);

    expect(controller.borrow?.id, 12);
    expect(controller.borrow?.status, 'borrowed');
    expect(controller.error, isNull);
  });

  test('2. requestReturn updates borrow status', () async {
    final api = FakeBorrowApi(detail: sampleBorrow(id: 12, status: 'borrowed'));
    final controller = BorrowDetailsController(borrowApi: api);
    await controller.load(12);

    final error = await controller.requestReturn();

    expect(error, isNull);
    expect(api.returnRequested, [12]);
    expect(controller.borrow?.status, 'returned_pending');
  });

  test('3. confirmReturn updates borrow status', () async {
    final api = FakeBorrowApi(
      detail: sampleBorrow(id: 12, status: 'returned_pending'),
    );
    final controller = BorrowDetailsController(borrowApi: api);
    await controller.load(12);

    final error = await controller.confirmReturn();

    expect(error, isNull);
    expect(api.returnConfirmed, [12]);
    expect(controller.borrow?.status, 'returned_confirmed');
  });
}
