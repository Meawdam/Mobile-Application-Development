import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/asset_api.dart';
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
  EditItemController({AssetApi? assetApi})
      : _assetApi = assetApi ?? AssetApi();

  final AssetApi _assetApi;

  AssetModel? asset;
  DateTime? lendingEndDate;
  bool loading = false;
  bool submitting = false;
  String? error;

  Future<void> load(int assetId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      asset = await _assetApi.getAssetById(assetId);
      lendingEndDate = AppDateUtils.tryParseYmd(asset?.returnBefore);
    } on ApiException catch (e) {
      asset = null;
      error = e.message;
    } catch (_) {
      asset = null;
      error = 'Unable to load item';
    } finally {
      loading = false;
      notifyListeners();
    }
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
    if (int.tryParse(trimmedPrice) == null || int.parse(trimmedPrice) < 0) {
      return EditItemResult.invalidPrice;
    }
    if (num.tryParse(trimmedDeposit) == null ||
        num.parse(trimmedDeposit) < 0) {
      return EditItemResult.invalidDeposit;
    }

    submitting = true;
    error = null;
    notifyListeners();
    try {
      asset = await _assetApi.updateAsset(
        id: id,
        name: trimmedName,
        description: trimmedDescription,
        downPayment: trimmedDeposit,
        price: trimmedPrice,
        pickupPoint: trimmedPickup,
        returnBefore: AppDateUtils.formatYmd(lendingEndDate!),
      );
      return EditItemResult.success;
    } on ApiException catch (e) {
      error = e.message;
      return EditItemResult.failed;
    } catch (_) {
      error = 'Unable to save changes';
      return EditItemResult.failed;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}
