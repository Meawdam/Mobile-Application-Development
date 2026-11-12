import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/asset_api.dart';
import 'package:frontend/services/borrow_api.dart';
import 'package:frontend/utils/date_utils.dart';

class BorrowRequestController extends ChangeNotifier {
  BorrowRequestController({
    AssetApi? assetApi,
    BorrowApi? borrowApi,
  })  : _assetApi = assetApi ?? AssetApi(),
        _borrowApi = borrowApi ?? BorrowApi();

  final AssetApi _assetApi;
  final BorrowApi _borrowApi;

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

  DateTime? get lendingEndDate =>
      AppDateUtils.tryParseYmd(_asset?.returnBefore);

  DateTime get earliestPickup => AppDateUtils.today();

  bool get datesValid {
    final end = lendingEndDate;
    if (_pickupDate == null || _returnDate == null || end == null) {
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

    try {
      _asset = await _assetApi.getAssetById(assetId);
      _pickupDate = null;
      _returnDate = null;

      final end = lendingEndDate;
      if (end == null || end.isBefore(earliestPickup)) {
        _error = 'This item has no valid lending end date';
      }
    } on ApiException catch (error) {
      _asset = null;
      _error = error.message;
    } catch (_) {
      _asset = null;
      _error = 'Unable to load item for borrow request';
    } finally {
      _loading = false;
      notifyListeners();
    }
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

    try {
      final borrow = await _borrowApi.requestBorrow(
        assetId: _asset!.id,
        pickupDate: AppDateUtils.formatYmd(_pickupDate!),
        returnDate: AppDateUtils.formatYmd(_returnDate!),
      );
      return borrow;
    } on ApiException catch (error) {
      _error = error.message;
      return null;
    } catch (_) {
      _error = 'Unable to submit borrow request';
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
