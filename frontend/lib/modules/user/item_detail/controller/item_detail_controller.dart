import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/item_detail/service/item_detail_api_service.dart';

class ItemDetailController extends ChangeNotifier {
  ItemDetailController({List<AssetModel>? items, this.apiService})
    : _items = items ?? <AssetModel>[];

  final List<AssetModel> _items;
  final ItemDetailApiService? apiService;
  AssetModel? _asset;
  bool _loading = false;
  bool _disposed = false;
  int _loadGeneration = 0;
  String? _error;

  AssetModel? get asset => _asset;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(int assetId) async {
    if (_disposed) return;
    final generation = ++_loadGeneration;
    _loading = true;
    _error = null;
    _asset = null;
    notifyListeners();

    try {
      final service = apiService;
      if (service != null) {
        _asset = await service.fetchAsset(assetId);
      } else {
        for (final item in _items) {
          if (item.id == assetId) {
            _asset = item;
            break;
          }
        }
        if (_asset == null) _error = 'Item not found';
      }
    } on Exception catch (exception) {
      if (!_disposed && generation == _loadGeneration) {
        _error = exception.toString();
      }
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
