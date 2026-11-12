import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/borrow_request/controller/borrow_request_controller.dart';
import 'package:frontend/utils/date_utils.dart';

import '../../helpers/test_fakes.dart';

void main() {
  late FakeAssetApi assetApi;
  late FakeBorrowApi borrowApi;
  late BorrowRequestController controller;
  late DateTime today;
  late DateTime end;

  setUp(() {
    today = AppDateUtils.today();
    end = today.add(const Duration(days: 10));
    assetApi = FakeAssetApi(
      byId: sampleAsset(
        id: 5,
        price: 100,
        downPayment: 500,
        returnBefore: AppDateUtils.formatYmd(end),
      ),
    );
    borrowApi = FakeBorrowApi();
    controller = BorrowRequestController(
      assetApi: assetApi,
      borrowApi: borrowApi,
    );
  });

  test('1. load sets asset and clears previous dates', () async {
    await controller.load(5);

    expect(controller.asset?.id, 5);
    expect(controller.pickupDate, isNull);
    expect(controller.returnDate, isNull);
    expect(controller.lendingEndDate, end);
  });

  test('2. valid dates compute rental days and totals', () async {
    await controller.load(5);
    controller.setPickupDate(today);
    controller.setReturnDate(today.add(const Duration(days: 2)));

    expect(controller.datesValid, isTrue);
    expect(controller.rentalDayCount, 3);
    expect(controller.rentalSubtotal, 300);
    expect(controller.deposit, 500);
    expect(controller.total, 800);
  });

  test('3. rejects return dates outside the lending window', () async {
    await controller.load(5);
    controller.setPickupDate(today);
    controller.setReturnDate(end.add(const Duration(days: 1)));

    expect(controller.returnDate, isNull);
    expect(controller.datesValid, isFalse);
  });

  test('4. submitRequest creates a borrow when dates are valid', () async {
    await controller.load(5);
    controller.setPickupDate(today);
    controller.setReturnDate(today.add(const Duration(days: 1)));

    final borrow = await controller.submitRequest();

    expect(borrow, isNotNull);
    expect(borrow!.assetId, 5);
    expect(borrow.status, 'requested');
    expect(controller.submitting, isFalse);
  });

  test('5. submitRequest fails without dates', () async {
    await controller.load(5);

    final borrow = await controller.submitRequest();

    expect(borrow, isNull);
    expect(controller.error, contains('Choose pickup and return dates'));
  });
}
