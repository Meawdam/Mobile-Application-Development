import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/model/user/user_model.dart';
import 'package:frontend/modules/user/home/service/home_api_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    List<AssetModel>? availableItems,
    UserModel? initialUser,
    this.apiService,
  }) : _availableItems = availableItems ?? <AssetModel>[],
       _user = initialUser;

  final List<AssetModel> _availableItems;
  final HomeApiService? apiService;
  List<AssetModel> _items = const [];
  UserModel? _user;
  bool _loading = false;
  bool _disposed = false;
  int _loadGeneration = 0;
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
    if (_disposed) return;
    _query = query?.trim() ?? _query;
    final generation = ++_loadGeneration;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final service = apiService;
      final items = service == null
          ? _filterAvailableItems()
          : await service.fetchAvailableAssets(query: _query);
      if (_disposed || generation != _loadGeneration) return;
      _items = items;
    } on Exception catch (exception) {
      if (_disposed || generation != _loadGeneration) return;
      _error = exception.toString();
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  List<AssetModel> _filterAvailableItems() {
    final normalizedQuery = _query.toLowerCase();
    return _availableItems.where((asset) {
      final available =
          (asset.status == 'available' || asset.status == 'ready') &&
          asset.approval == 'approved';
      final matchesQuery =
          normalizedQuery.isEmpty ||
          asset.name.toLowerCase().contains(normalizedQuery) ||
          asset.description.toLowerCase().contains(normalizedQuery);
      return available && matchesQuery;
    }).toList();
  }

  Future<void> search(String value) => loadItems(query: value);

  Future<void> logout() async {}

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
