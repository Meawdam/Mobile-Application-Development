import 'dart:convert';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class ItemDetailApiException implements Exception {
  const ItemDetailApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ItemDetailApiService {
  ItemDetailApiService({
    http.Client? client,
    Authservice? authService,
    this.baseUrl = 'http://localhost:3000',
  }) : _client = client ?? http.Client(),
       _authService = authService ?? Authservice();

  final http.Client _client;
  final Authservice _authService;
  final String baseUrl;

  void dispose() => _client.close();

  Future<AssetModel> fetchAsset(int assetId) async {
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
}
