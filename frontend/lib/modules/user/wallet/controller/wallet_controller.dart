import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:frontend/model/wallet/wallet_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class WalletController extends ChangeNotifier {
  WalletController({
    num initialBalance = 0,
    http.Client? client,
    Authservice? authService,
    this.baseUrl = 'http://localhost:3000',
  }) : balance = initialBalance,
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _authService = authService ?? Authservice();

  final http.Client _client;
  final bool _ownsClient;
  final Authservice _authService;
  final String baseUrl;
  num balance;
  bool loading = false;
  bool submitting = false;
  String? error;
  String? loadError;
  bool _disposed = false;
  int _balanceRevision = 0;

  Future<void> load() async {
    if (_disposed) return;
    final revision = _balanceRevision;
    loading = true;
    error = null;
    loadError = null;
    notifyListeners();
    try {
      final wallet = await _fetchWallet();
      if (!_disposed && revision == _balanceRevision) {
        balance = wallet.balance;
      }
    } on Exception catch (exception) {
      if (!_disposed) loadError = exception.toString();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> topUpOnline(num amount) async {
    if (_disposed || submitting) return false;
    if (amount <= 0) {
      error = 'Enter a positive amount';
      notifyListeners();
      return false;
    }

    submitting = true;
    error = null;
    notifyListeners();
    try {
      final headers = await _authorizedHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await _client.post(
        Uri.parse('$baseUrl/api/wallet/top-up'),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );
      final wallet = WalletModel.fromJson(_readData(response));
      if (_disposed) return false;
      _balanceRevision++;
      balance = wallet.balance;
      loadError = null;
      return true;
    } on Exception catch (exception) {
      if (!_disposed) error = exception.toString();
      return false;
    } finally {
      submitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<WalletModel> _fetchWallet() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/wallet'),
      headers: await _authorizedHeaders(),
    );
    return WalletModel.fromJson(_readData(response));
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _authService.loadToken();
    if (token == null || token.isEmpty) {
      throw const WalletApiException('Please sign in to access your wallet.');
    }
    return {'Authorization': 'Bearer $token'};
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

  @override
  void dispose() {
    _disposed = true;
    if (_ownsClient) _client.close();
    super.dispose();
  }
}

class WalletApiException implements Exception {
  const WalletApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
