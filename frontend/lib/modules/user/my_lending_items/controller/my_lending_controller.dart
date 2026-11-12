import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/asset_api.dart';

class MyLendingController extends ChangeNotifier {
  MyLendingController({AssetApi? assetApi})
      : _assetApi = assetApi ?? AssetApi();

  final AssetApi _assetApi;

  List<AssetModel> items = const [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _assetApi.getMyAssets();
    } on ApiException catch (e) {
      error = e.message;
      items = const [];
    } catch (_) {
      error = 'Unable to load lending items';
      items = const [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteAsset(int id) async {
    try {
      await _assetApi.deleteAsset(id);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to delete item';
    }
  }
}
