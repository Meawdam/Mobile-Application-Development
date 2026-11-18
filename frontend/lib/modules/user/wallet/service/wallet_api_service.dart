import 'dart:convert';

import 'package:frontend/model/wallet/wallet_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class WalletApiException implements Exception {
  const WalletApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WalletApiService {
  WalletApiService({
    http.Client? client,
    Authservice? authService,
    this.baseUrl = 'http://localhost:3000',
  }) : _client = client ?? http.Client(),
       _authService = authService ?? Authservice();

  final http.Client _client;
  final Authservice _authService;
  final String baseUrl;

  void dispose() => _client.close();

  Future<WalletModel> fetchWallet() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/wallet'),
      headers: await _authorizedHeaders(),
    );
    return WalletModel.fromJson(_readData(response));
  }

  Future<WalletModel> topUp(num amount) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/wallet/top-up'),
      headers: await _authorizedHeaders(),
      body: jsonEncode({'amount': amount}),
    );
    return WalletModel.fromJson(_readData(response));
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _authService.loadToken();
    if (token == null || token.isEmpty) {
      throw const WalletApiException('Please sign in to access your wallet.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _readData(http.Response response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('The server returned an invalid response');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw WalletApiException(
        message == null || message.isEmpty
            ? 'Wallet request failed (${response.statusCode})'
            : message,
      );
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid wallet response');
    }
    return decoded['data'] as Map<String, dynamic>;
  }
}
