import 'package:frontend/model/borrow/borrow_model.dart';

import 'api_client.dart';

class BorrowPayResult {
  final int borrowId;
  final int? walletBalance;
  final num? totalAmount;

  const BorrowPayResult({
    required this.borrowId,
    this.walletBalance,
    this.totalAmount,
  });
}

class BorrowApi {
  BorrowApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<BorrowModel> requestBorrow({
    required int assetId,
    required String pickupDate,
    required String returnDate,
  }) async {
    final response = await _client.post(
      '/api/borrows',
      body: {
        'asset_id': assetId,
        'pickup_date': pickupDate,
        'return_date': returnDate,
      },
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(500, 'Invalid borrow response from server');
    }
    return BorrowModel.fromJson(data);
  }

  Future<BorrowPayResult> pay(int borrowId) async {
    final response = await _client.post('/api/borrows/$borrowId/pay');
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return BorrowPayResult(
        borrowId: borrowId,
        walletBalance: _asInt(data['wallet_balance']),
        totalAmount: _asNum(data['total_amount']),
      );
    }
    return BorrowPayResult(borrowId: borrowId);
  }

  Future<BorrowModel> getBorrowById(int id) async {
    final response = await _client.get('/api/borrows/$id');
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(500, 'Invalid borrow detail response');
    }
    return BorrowModel.fromJson(data);
  }

  Future<List<BorrowModel>> getMyBorrows() async {
    final response = await _client.get('/api/borrows/my');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(BorrowModel.fromJson)
        .toList();
  }

  Future<List<BorrowModel>> getMyLendingBorrows() async {
    final response = await _client.get('/api/borrows/lending');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(BorrowModel.fromJson)
        .toList();
  }

  Future<void> cancel(int borrowId) async {
    await _client.patch('/api/borrows/$borrowId/cancel');
  }

  Future<void> requestReturn(int borrowId) async {
    await _client.patch('/api/borrows/$borrowId/return');
  }

  Future<void> confirmReturn(int borrowId) async {
    await _client.patch('/api/borrows/$borrowId/confirm-return');
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static num? _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}
