import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/model/user/user_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class HomeController extends ChangeNotifier {
  HomeController({
    List<AssetModel>? availableItems,
    UserModel? initialUser,
    http.Client? client,
    Authservice? authService,
    this.baseUrl = 'http://localhost:3000',
  }) : _availableItems = availableItems ?? <AssetModel>[],
       _useFixtures = availableItems != null,
       _user = initialUser,
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _authService = authService ?? Authservice();

  final List<AssetModel> _availableItems;
  final bool _useFixtures;
  final http.Client _client;
  final bool _ownsClient;
  final Authservice _authService;
  final String baseUrl;
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
    if (_user == null) {
      _user =
          (_useFixtures ? null : await _readUserFromToken()) ??
          const UserModel(
            username: '',
            phoneNumber: '',
            email: '',
            role: 'user',
          );
    }
    await loadItems();
  }

  Future<UserModel?> _readUserFromToken() async {
    final token = await _authService.loadToken();
    if (token == null) return null;
    try {
      final segments = token.split('.');
      if (segments.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
      if (payload is! Map<String, dynamic>) return null;
      return UserModel(
        username: payload['username']?.toString() ?? '',
        phoneNumber: payload['phone_num']?.toString() ?? '',
        email: payload['email']?.toString() ?? '',
        role: payload['role']?.toString() ?? 'user',
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> loadItems({String? query}) async {
    if (_disposed) return;
    _query = query?.trim() ?? _query;
    final generation = ++_loadGeneration;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final items = _useFixtures
          ? _filterAvailableItems()
          : await _fetchAvailableAssets();
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

  Future<List<AssetModel>> _fetchAvailableAssets() async {
    final token = await _authService.loadToken();
    final query = _query.trim();
    final uri = Uri.parse('$baseUrl/api/assets')
        .replace(queryParameters: query.isEmpty ? null : {'q': query});
    final response = await _client.get(
      uri,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    final data = _readData(response);
    if (data is! List) {
      throw const FormatException('Invalid available-items response');
    }

    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid item in available-items response');
      }
      final normalizedItem = Map<String, dynamic>.from(item);
      final image = normalizedItem['image']?.toString();
      if (image != null && image.startsWith('/')) {
        normalizedItem['image'] = '$baseUrl$image';
      }
      return AssetModel.fromJson(normalizedItem);
    }).toList();
  }

  dynamic _readData(http.Response response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('The server returned an invalid response');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw HomeApiException(
        message == null || message.isEmpty
            ? 'Could not load items (${response.statusCode})'
            : message,
      );
    }
    if (decoded is! Map<String, dynamic> || !decoded.containsKey('data')) {
      throw const FormatException('Invalid available-items response');
    }
    return decoded['data'];
  }

  Future<void> search(String value) => loadItems(query: value);

  Future<void> logout() async {}

  @override
  void dispose() {
    _disposed = true;
    if (_ownsClient) _client.close();
    super.dispose();
  }
}

class HomeApiException implements Exception {
  const HomeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
