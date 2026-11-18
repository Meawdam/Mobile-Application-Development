import 'dart:convert';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/model/wallet/wallet_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class PaymentApiException implements Exception {
  const PaymentApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentApiResult {
  const PaymentApiResult({
    required this.borrowId,
    required this.walletBalance,
    required this.status,
    required this.paymentStatus,
  });

  final int borrowId;
  final num walletBalance;
  final String status;
  final String paymentStatus;
}

class PaymentApiService {
  PaymentApiService({
    http.Client? client,
    Authservice? authService,
    this.baseUrl = 'http://localhost:3000',
  }) : _client = client ?? http.Client(),
       _authService = authService ?? Authservice();

  final http.Client _client;
  final Authservice _authService;
  final String baseUrl;

  void dispose() => _client.close();

  Future<num> fetchWalletBalance() async {
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

  Future<BorrowModel> fetchBorrow(int borrowId) async {
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

  Future<PaymentApiResult> pay(int borrowId) async {
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

    return PaymentApiResult(
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
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid payment response');
    }

    if (decoded['data'] is Map<String, dynamic>) {
      return decoded['data'];
    }
    throw const FormatException('Invalid payment response');
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
}
