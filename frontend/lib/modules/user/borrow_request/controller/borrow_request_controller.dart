import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/utils/date_utils.dart';

class BorrowRequestController extends ChangeNotifier {
  BorrowRequestController({
    List<AssetModel>? assets,
    List<BorrowModel>? borrows,
  })  : _assets = assets ?? <AssetModel>[],
        _borrows = borrows ?? <BorrowModel>[];

  final List<AssetModel> _assets;
  final List<BorrowModel> _borrows;
  AssetModel? _asset;
  bool _loading = false;
  bool _submitting = false;
  String? _error;
  DateTime? _pickupDate;
  DateTime? _returnDate;

  AssetModel? get asset => _asset;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  DateTime? get pickupDate => _pickupDate;
  DateTime? get returnDate => _returnDate;
  List<BorrowModel> get borrows => List.unmodifiable(_borrows);

  DateTime? get lendingEndDate =>
      AppDateUtils.tryParseYmd(_asset?.returnBefore);

  DateTime get earliestPickup => AppDateUtils.today();

  bool get datesValid {
    final end = lendingEndDate;
    final currentAsset = _asset;
    if (currentAsset == null ||
        (currentAsset.status != 'available' &&
            currentAsset.status != 'ready') ||
        currentAsset.approval != 'approved' ||
        _pickupDate == null ||
        _returnDate == null ||
        end == null) {
      return false;
    }
    if (_returnDate!.isBefore(_pickupDate!)) return false;
    if (_pickupDate!.isBefore(earliestPickup)) return false;
    if (_pickupDate!.isAfter(end) || _returnDate!.isAfter(end)) return false;
    return true;
  }

  int get rentalDayCount {
    if (_pickupDate == null || _returnDate == null) return 0;
    return AppDateUtils.rentalDays(_pickupDate!, _returnDate!);
  }

  num get rentalSubtotal {
    final price = _asset?.price ?? 0;
    return price * rentalDayCount;
  }

  num get deposit => _asset?.downPayment ?? 0;

  num get total => rentalSubtotal + deposit;

  Future<void> load(int assetId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    _asset = null;
    for (final item in _assets) {
      if (item.id == assetId) {
        _asset = item;
        break;
      }
    }
    _pickupDate = null;
    _returnDate = null;
    if (_asset == null) {
      _error = 'Item not found';
    } else if ((_asset!.status != 'available' && _asset!.status != 'ready') ||
        _asset!.approval != 'approved') {
      _error = 'Item is not available for borrowing';
    } else {
      final end = lendingEndDate;
      if (end == null || end.isBefore(earliestPickup)) {
        _error = 'This item has no valid lending end date';
      }
    }
    _loading = false;
    notifyListeners();
  }

  void setPickupDate(DateTime date) {
    final end = lendingEndDate;
    if (end == null) return;

    final picked = AppDateUtils.dateOnly(date);
    if (!AppDateUtils.isWithinRange(
      picked,
      first: earliestPickup,
      last: end,
    )) {
      return;
    }

    _pickupDate = picked;
    if (_returnDate != null && _returnDate!.isBefore(picked)) {
      _returnDate = null;
    }
    if (_returnDate != null && _returnDate!.isAfter(end)) {
      _returnDate = null;
    }
    notifyListeners();
  }

  void setReturnDate(DateTime date) {
    final end = lendingEndDate;
    if (end == null || _pickupDate == null) return;

    final picked = AppDateUtils.dateOnly(date);
    if (!AppDateUtils.isWithinRange(
      picked,
      first: _pickupDate!,
      last: end,
    )) {
      return;
    }

    _returnDate = picked;
    notifyListeners();
  }

  Future<BorrowModel?> submitRequest() async {
    if (!datesValid || _asset == null) {
      _error = 'Choose pickup and return dates within the lender timeframe';
      notifyListeners();
      return null;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    final asset = _asset!;
    final nextId = _borrows.fold<int>(
          0,
          (maxId, item) => item.id > maxId ? item.id : maxId,
        ) +
        1;
    final borrow = BorrowModel(
      id: nextId,
      assetId: asset.id,
      assetName: asset.name,
      ownerName: asset.ownerUsername,
      borrowerName: 'Guest',
      pickupPoint: asset.pickupPoint,
      pickupDate: AppDateUtils.formatYmd(_pickupDate!),
      plannedReturnDate: AppDateUtils.formatYmd(_returnDate!),
      rentalDays: rentalDayCount,
      lendingEndDate: asset.returnBefore,
      pricePerDay: asset.price,
      rentalSubtotal: rentalSubtotal,
      deposit: deposit,
      totalAmount: total,
      status: 'requested',
      paymentStatus: 'unpaid',
    );
    _borrows.add(borrow);
    _submitting = false;
    notifyListeners();
    return borrow;
  }
}
