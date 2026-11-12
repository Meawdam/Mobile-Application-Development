import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/asset_api.dart';

class ItemDetailController extends ChangeNotifier {
  ItemDetailController({AssetApi? assetApi})
      : _assetApi = assetApi ?? AssetApi();

  final AssetApi _assetApi;

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

    try {
      _asset = await _assetApi.getAssetById(assetId);
    } on ApiException catch (error) {
      _asset = null;
      _error = error.message;
    } catch (_) {
      _asset = null;
      _error = 'Unable to load item details';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
