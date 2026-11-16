import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';

class ItemDetailController extends ChangeNotifier {
  ItemDetailController({List<AssetModel>? items})
      : _items = items ?? <AssetModel>[];

  final List<AssetModel> _items;
  AssetModel? _asset;
  bool _loading = false;
  String? _error;

  AssetModel? get asset => _asset;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(int assetId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    _asset = null;
    for (final item in _items) {
      if (item.id == assetId) {
        _asset = item;
        break;
      }
    }
    if (_asset == null) _error = 'Item not found';
    _loading = false;
    notifyListeners();
  }
}
