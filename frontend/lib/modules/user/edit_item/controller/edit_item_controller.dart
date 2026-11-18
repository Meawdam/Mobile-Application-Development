import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/utils/date_utils.dart';

enum EditItemResult {
  success,
  missingFields,
  invalidPrice,
  invalidDeposit,
  missingLendingEndDate,
  failed,
}

class EditItemController extends ChangeNotifier {
  EditItemController({List<AssetModel>? items})
      : _items = items ?? <AssetModel>[];

  final List<AssetModel> _items;
  AssetModel? asset;
  DateTime? lendingEndDate;
  bool loading = false;
  bool submitting = false;
  String? error;

  Future<void> load(int assetId) async {
    loading = true;
    error = null;
    notifyListeners();
    asset = null;
    for (final item in _items) {
      if (item.id == assetId) {
        asset = item;
        break;
      }
    }
    lendingEndDate = AppDateUtils.tryParseYmd(asset?.returnBefore);
    if (asset == null) error = 'Item not found';
    loading = false;
    notifyListeners();
  }

  void setLendingEndDate(DateTime date) {
    lendingEndDate = AppDateUtils.dateOnly(date);
    notifyListeners();
  }

  Future<EditItemResult> save({
    required String name,
    required String description,
    required String price,
    required String deposit,
    required String pickupPoint,
  }) async {
    final id = asset?.id;
    if (id == null) return EditItemResult.failed;

    final trimmedName = name.trim();
    final trimmedDescription = description.trim();
    final trimmedPickup = pickupPoint.trim();
    final trimmedPrice = price.trim();
    final trimmedDeposit = deposit.trim();

    if (trimmedName.isEmpty ||
        trimmedDescription.isEmpty ||
        trimmedPickup.isEmpty ||
        trimmedPrice.isEmpty ||
        trimmedDeposit.isEmpty) {
      return EditItemResult.missingFields;
    }
    if (lendingEndDate == null) {
      return EditItemResult.missingLendingEndDate;
    }
    final parsedPrice = int.tryParse(trimmedPrice);
    if (parsedPrice == null ||
        parsedPrice < 0 ||
        parsedPrice > 2147483647) {
      return EditItemResult.invalidPrice;
    }
    final parsedDeposit = num.tryParse(trimmedDeposit);
    if (parsedDeposit == null ||
        !parsedDeposit.isFinite ||
        parsedDeposit < 0) {
      return EditItemResult.invalidDeposit;
    }

    submitting = true;
    error = null;
    notifyListeners();
    final current = asset!;
    final updated = AssetModel(
      id: current.id,
      ownerId: current.ownerId,
      ownerUsername: current.ownerUsername,
      image: current.image,
      name: trimmedName,
      description: trimmedDescription,
      status: current.status,
      approval: current.approval,
      approvalMessage: current.approvalMessage,
      downPayment: parsedDeposit,
      returnBefore: AppDateUtils.formatYmd(lendingEndDate!),
      price: parsedPrice,
      pickupPoint: trimmedPickup,
    );
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      error = 'Item not found';
      submitting = false;
      notifyListeners();
      return EditItemResult.failed;
    }

    _items[index] = updated;
    asset = updated;
    submitting = false;
    notifyListeners();
    return EditItemResult.success;
  }
}
