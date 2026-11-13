import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/model/user/user_model.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    List<AssetModel>? availableItems,
    UserModel? initialUser,
  })  : _availableItems = availableItems ?? <AssetModel>[],
        _user = initialUser;

  final List<AssetModel> _availableItems;
  List<AssetModel> _items = const [];
  UserModel? _user;
  bool _loading = false;
  String? _error;
  String _query = '';

  List<AssetModel> get items => List.unmodifiable(_items);
  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;

  Future<void> initialize() async {
    _user ??= const UserModel(
      username: 'Guest',
      phoneNumber: '',
      email: '',
      role: 'user',
    );
    await loadItems();
  }

  Future<void> loadItems({String? query}) async {
    _query = query?.trim() ?? _query;
    _loading = true;
    _error = null;
    notifyListeners();

    final normalizedQuery = _query.toLowerCase();
    _items = _availableItems.where((asset) {
      final available =
          (asset.status == 'available' || asset.status == 'ready') &&
              asset.approval == 'approved';
      final matchesQuery = normalizedQuery.isEmpty ||
          asset.name.toLowerCase().contains(normalizedQuery) ||
          asset.description.toLowerCase().contains(normalizedQuery);
      return available && matchesQuery;
    }).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String value) => loadItems(query: value);

  Future<void> logout() async {}
}
