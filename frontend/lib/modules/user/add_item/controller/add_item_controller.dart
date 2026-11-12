import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/asset_api.dart';
import 'package:frontend/utils/date_utils.dart';

enum AddItemResult {
  success,
  missingFields,
  invalidPrice,
  invalidDeposit,
  missingImage,
  missingLendingEndDate,
  failed,
}

class AddItemController extends ChangeNotifier {
  AddItemController({AssetApi? assetApi, ImagePicker? picker})
      : _assetApi = assetApi ?? AssetApi(),
        _picker = picker ?? ImagePicker();

  final AssetApi _assetApi;
  final ImagePicker _picker;

  Uint8List? _imageBytes;
  String? _imageName;
  DateTime? _lendingEndDate;
  bool _submitting = false;
  String? _error;

  Uint8List? get imageBytes => _imageBytes;
  DateTime? get lendingEndDate => _lendingEndDate;
  bool get submitting => _submitting;
  String? get error => _error;

  Future<void> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setPickedImage(await file.readAsBytes(), file.name);
  }

  void setPickedImage(Uint8List bytes, String name) {
    _imageBytes = bytes;
    _imageName = name;
    notifyListeners();
  }

  void setLendingEndDate(DateTime date) {
    _lendingEndDate = AppDateUtils.dateOnly(date);
    notifyListeners();
  }

  Future<AddItemResult> submit({
    required String name,
    required String description,
    required String price,
    required String deposit,
    required String pickupPoint,
  }) async {
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
      return AddItemResult.missingFields;
    }

    if (_imageBytes == null || _imageName == null) {
      return AddItemResult.missingImage;
    }

    if (_lendingEndDate == null) {
      return AddItemResult.missingLendingEndDate;
    }

    if (int.tryParse(trimmedPrice) == null || int.parse(trimmedPrice) < 0) {
      return AddItemResult.invalidPrice;
    }

    if (num.tryParse(trimmedDeposit) == null ||
        num.parse(trimmedDeposit) < 0) {
      return AddItemResult.invalidDeposit;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      await _assetApi.createAsset(
        name: trimmedName,
        description: trimmedDescription,
        downPayment: trimmedDeposit,
        price: trimmedPrice,
        pickupPoint: trimmedPickup,
        returnBefore: AppDateUtils.formatYmd(_lendingEndDate!),
        imageBytes: _imageBytes!,
        imageFilename: _imageName!,
      );
      return AddItemResult.success;
    } on ApiException catch (error) {
      _error = error.message;
      return AddItemResult.failed;
    } catch (_) {
      _error = 'Unable to submit item';
      return AddItemResult.failed;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
