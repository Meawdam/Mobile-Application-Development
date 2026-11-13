import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:frontend/model/asset/asset_model.dart';
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
  AddItemController({List<AssetModel>? items, ImagePicker? picker})
      : _items = items ?? <AssetModel>[],
        _picker = picker ?? ImagePicker();

  final List<AssetModel> _items;
  final ImagePicker _picker;

  Uint8List? _imageBytes;
  String? _imageName;
  DateTime? _lendingEndDate;
  bool _submitting = false;
  String? _error;

  Uint8List? get imageBytes => _imageBytes;
  List<AssetModel> get items => List.unmodifiable(_items);
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

    final parsedPrice = int.tryParse(trimmedPrice);
    if (parsedPrice == null ||
        parsedPrice < 0 ||
        parsedPrice > 2147483647) {
      return AddItemResult.invalidPrice;
    }

    final parsedDeposit = num.tryParse(trimmedDeposit);
    if (parsedDeposit == null ||
        !parsedDeposit.isFinite ||
        parsedDeposit < 0) {
      return AddItemResult.invalidDeposit;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    final nextId = _items.fold<int>(
          0,
          (maxId, item) => item.id > maxId ? item.id : maxId,
        ) +
        1;
    _items.add(
      AssetModel(
        id: nextId,
        ownerId: 1,
        ownerUsername: 'Guest',
        image: _imageName,
        name: trimmedName,
        description: trimmedDescription,
        status: 'ready',
        approval: 'pending',
        downPayment: parsedDeposit,
        returnBefore: AppDateUtils.formatYmd(_lendingEndDate!),
        price: parsedPrice,
        pickupPoint: trimmedPickup,
      ),
    );
    _submitting = false;
    notifyListeners();
    return AddItemResult.success;
  }
}
