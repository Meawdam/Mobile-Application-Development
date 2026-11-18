import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class ItemDetailController extends ChangeNotifier {
  ItemDetailController({
    List<AssetModel>? items,
    http.Client? client,
    Authservice? authService,
    this.baseUrl = 'http://localhost:3000',
  }) : _items = items ?? <AssetModel>[],
       _useFixtures = items != null,
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _authService = authService ?? Authservice();

  final List<AssetModel> _items;
  final bool _useFixtures;
  final http.Client _client;
  final bool _ownsClient;
  final Authservice _authService;
  final String baseUrl;
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
      final AssetModel? loadedAsset;
      if (_useFixtures) {
        loadedAsset = _findFixture(assetId);
      } else {
        loadedAsset = await _fetchAsset(assetId);
      }
      if (_disposed || generation != _loadGeneration) return;
      _asset = loadedAsset;
      if (_asset == null) {
        _error = 'Item not found';
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

  AssetModel? _findFixture(int assetId) {
    for (final item in _items) {
      if (item.id == assetId) return item;
    }
    return null;
  }

  Future<AssetModel> _fetchAsset(int assetId) async {
    final token = await _authService.loadToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/api/assets/$assetId'),
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    final data = _readData(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid item details response');
    }

    final asset = Map<String, dynamic>.from(data);
    final image = asset['image']?.toString();
    if (image != null && image.startsWith('/')) {
      asset['image'] = '$baseUrl$image';
    }
    return AssetModel.fromJson(asset);
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
      throw ItemDetailApiException(
        message == null || message.isEmpty
            ? 'Could not load item (${response.statusCode})'
            : message,
      );
    }
    if (decoded is! Map<String, dynamic> || !decoded.containsKey('data')) {
      throw const FormatException('Invalid item details response');
    }
    return decoded['data'];
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsClient) _client.close();
    super.dispose();
  }
}

class ItemDetailApiException implements Exception {
  const ItemDetailApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
