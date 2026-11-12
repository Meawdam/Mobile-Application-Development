import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/model/user/user_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/asset_api.dart';
import 'package:frontend/services/auth_api.dart';
import 'package:frontend/services/auth_session.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    AssetApi? assetApi,
    AuthApi? authApi,
    AuthSession? session,
  })  : _assetApi = assetApi ?? AssetApi(),
        _authApi = authApi ?? AuthApi(),
        _session = session ?? AuthSession.instance;

  final AssetApi _assetApi;
  final AuthApi _authApi;
  final AuthSession _session;

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
    _user = await _session.getUser();
    notifyListeners();
    await loadItems();
  }

  Future<void> loadItems({String? query}) async {
    _query = query?.trim() ?? _query;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _assetApi.getAvailableAssets(
        query: _query.isEmpty ? null : _query,
      );
    } on ApiException catch (error) {
      _items = const [];
      _error = error.message;
    } catch (_) {
      _items = const [];
      _error = 'Unable to load items';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String value) => loadItems(query: value);

  Future<void> logout() => _authApi.logout();
}
