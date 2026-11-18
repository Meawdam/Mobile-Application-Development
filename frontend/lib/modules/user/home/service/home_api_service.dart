import 'dart:convert';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class HomeApiException implements Exception {
  const HomeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HomeApiService {
  HomeApiService({
    http.Client? client,
    Authservice? authService,
    this.baseUrl = 'http://localhost:3000',
  }) : _client = client ?? http.Client(),
       _authService = authService ?? Authservice();

  final http.Client _client;
  final Authservice _authService;
  final String baseUrl;

  void dispose() => _client.close();

  Future<List<AssetModel>> fetchAvailableAssets({String query = ''}) async {
    final token = await _authService.loadToken();
    final uri = Uri.parse('$baseUrl/api/assets').replace(
      queryParameters: query.trim().isEmpty ? null : {'q': query.trim()},
    );
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
}
