import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/model/wallet/wallet_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class PaymentResult {
  final int borrowId;
  final num walletBalance;
  final String status;
  final String paymentStatus;

  const PaymentResult({
    required this.borrowId,
    required this.walletBalance,
    required this.status,
    required this.paymentStatus,
  });
}

class PaymentController extends ChangeNotifier {
  PaymentController({
    this.walletBalance = 0,
    http.Client? client,
    Authservice? authService,
    this.baseUrl = 'http://localhost:3000',
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _authService = authService ?? Authservice();

  final http.Client _client;
  final bool _ownsClient;
  final Authservice _authService;
  final String baseUrl;
  num walletBalance;
  BorrowModel? borrow;
  bool loading = false;
  bool paying = false;
  String? error;
  String? loadError;
  bool _disposed = false;

  Future<void> loadWallet() async {
    if (_disposed) return;
    loading = true;
    error = null;
    loadError = null;
    notifyListeners();
    try {
      walletBalance = await _fetchWalletBalance();
    } on Exception catch (exception) {
      if (!_disposed) loadError = exception.toString();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> loadPayment(int? borrowId) async {
    if (_disposed) return;
    if (borrowId == null) {
      borrow = null;
      loadError = 'Missing borrow request';
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    loadError = null;
    borrow = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _fetchWalletBalance(),
        _fetchBorrow(borrowId),
      ]);
      final walletResult = results[0];
      final borrowResult = results[1];
      if (walletResult is! num || borrowResult is! BorrowModel) {
        throw const FormatException('Invalid payment details response');
      }
      if (_disposed) return;
      walletBalance = walletResult;
      borrow = borrowResult;
    } on Exception catch (exception) {
      if (!_disposed) loadError = exception.toString();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  bool canPay(num total) => total >= 0 && walletBalance >= total;

  Future<PaymentResult?> confirmPayment({
    required int borrowId,
    required num total,
  }) async {
    if (_disposed || paying) return null;
    final currentBorrow = borrow;
    if (currentBorrow == null || currentBorrow.id != borrowId) {
      error = 'Borrow not found';
      notifyListeners();
      return null;
    }
    final amountDue = currentBorrow.totalAmount ?? total;
    if (amountDue < 0) {
      error = 'Invalid payment amount';
      notifyListeners();
      return null;
    }
    if (!canPay(amountDue)) {
      error = 'Insufficient wallet balance';
      notifyListeners();
      return null;
    }
    if (currentBorrow.paymentStatus == 'paid') {
      error = 'Borrow is already paid';
      notifyListeners();
      return null;
    }

    paying = true;
    error = null;
    notifyListeners();
    try {
      final result = await _submitPayment(borrowId);
      if (_disposed) return null;
      walletBalance = result.walletBalance;
      borrow = currentBorrow.copyWith(
        status: result.status,
        paymentStatus: result.paymentStatus,
      );
      return result;
    } on Exception catch (exception) {
      if (!_disposed) error = exception.toString();
      return null;
    } finally {
      paying = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<num> _fetchWalletBalance() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/wallet'),
      headers: await _authorizedHeaders(),
    );
    final data = _readData(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid wallet response');
    }
    return WalletModel.fromJson(data).balance;
  }

  Future<BorrowModel> _fetchBorrow(int borrowId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/borrows/$borrowId'),
      headers: await _authorizedHeaders(),
    );
    final data = _readData(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid borrow response');
    }
    return BorrowModel.fromJson(data);
  }

  Future<PaymentResult> _submitPayment(int borrowId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/borrows/$borrowId/pay'),
      headers: await _authorizedHeaders(),
    );
    final data = _readData(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid payment response');
    }

    final responseBorrowId = _asInt(data['borrow_id']);
    final walletBalance = _asNum(data['wallet_balance']);
    final status = data['status']?.toString();
    final paymentStatus = data['payment_status']?.toString();
    if (responseBorrowId == null ||
        responseBorrowId != borrowId ||
        walletBalance == null ||
        status == null ||
        paymentStatus != 'paid') {
      throw const FormatException('Invalid payment response');
    }
    return PaymentResult(
      borrowId: responseBorrowId,
      walletBalance: walletBalance,
      status: status,
      paymentStatus: 'paid',
    );
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _authService.loadToken();
    if (token == null || token.isEmpty) {
      throw const PaymentApiException('Please sign in to make a payment.');
    }
    return {'Authorization': 'Bearer $token'};
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
      throw PaymentApiException(
        message == null || message.isEmpty
            ? 'Payment request failed (${response.statusCode})'
            : message,
      );
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid payment response');
    }
    return decoded['data'];
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static num? _asNum(Object? value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsClient) _client.close();
    super.dispose();
  }
}

class PaymentApiException implements Exception {
  const PaymentApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
