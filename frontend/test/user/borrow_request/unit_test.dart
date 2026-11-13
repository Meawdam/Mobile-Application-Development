import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/borrow_request/controller/borrow_request_controller.dart';
import 'package:frontend/utils/date_utils.dart';

void main() {
  late List<AssetModel> assets;
  late List<BorrowModel> borrows;
  late BorrowRequestController controller;
  late DateTime today;
  late DateTime end;

  setUp(() {
    today = AppDateUtils.today();
    end = today.add(const Duration(days: 10));
    assets = [
      AssetModel(
          id: 5,
          ownerId: 2,
          ownerUsername: 'Lender',
          name: 'Camera',
          description: 'Digital camera',
          status: 'available',
          approval: 'approved',
          downPayment: 500,
          returnBefore: AppDateUtils.formatYmd(end),
          price: 100,
          pickupPoint: 'Canteen',
        ),
    ];
    borrows = [];
    controller = BorrowRequestController(assets: assets, borrows: borrows);
  });

  test('load sets asset and clears previous dates', () async {
    await controller.load(5);

    expect(controller.asset?.id, 5);
    expect(controller.pickupDate, isNull);
    expect(controller.returnDate, isNull);
    expect(controller.lendingEndDate, end);
  });

  test('valid dates compute rental days and totals', () async {
    await controller.load(5);
    controller.setPickupDate(today);
    controller.setReturnDate(today.add(const Duration(days: 2)));

    expect(controller.datesValid, isTrue);
    expect(controller.rentalDayCount, 3);
    expect(controller.rentalSubtotal, 300);
    expect(controller.deposit, 500);
    expect(controller.total, 800);
  });

  test('rejects return dates outside the lending window', () async {
    await controller.load(5);
    controller.setPickupDate(today);
    controller.setReturnDate(end.add(const Duration(days: 1)));

    expect(controller.returnDate, isNull);
    expect(controller.datesValid, isFalse);
  });

  test('submitRequest creates a local borrow when dates are valid', () async {
    await controller.load(5);
    controller.setPickupDate(today);
    controller.setReturnDate(today.add(const Duration(days: 1)));

    final borrow = await controller.submitRequest();

    expect(borrow, isNotNull);
    expect(borrow!.assetId, 5);
    expect(borrow.status, 'requested');
    expect(borrows.single, same(borrow));
    expect(controller.submitting, isFalse);
  });

  test('submitRequest fails without dates', () async {
    await controller.load(5);

    final borrow = await controller.submitRequest();

    expect(borrow, isNull);
    expect(controller.error, contains('Choose pickup and return dates'));
  });
}
