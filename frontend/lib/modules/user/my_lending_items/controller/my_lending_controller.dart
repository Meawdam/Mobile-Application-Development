import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';

class MyLendingController extends ChangeNotifier {
  MyLendingController({
    List<AssetModel>? items,
    this.currentUserId = 1,
  }) : _allItems = items ?? <AssetModel>[];

  final List<AssetModel> _allItems;
  final int currentUserId;
  List<AssetModel> items = const [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    items = _allItems
        .where((asset) => asset.ownerId == currentUserId)
        .toList();
    loading = false;
    notifyListeners();
  }

  Future<String?> deleteAsset(int id) async {
    final index = _allItems.indexWhere((asset) => asset.id == id);
    if (index == -1) return 'Item not found';
    final asset = _allItems[index];
    if (asset.ownerId != currentUserId) {
      return 'You cannot delete this item';
    }
    if (asset.status == 'borrowed') {
      return 'Item is currently borrowed';
    }
    _allItems.removeAt(index);
    await load();
    return null;
  }
}
