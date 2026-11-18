import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/services/auth_service.dart';

/// หน้า Requests & Returns (ฝั่งเจ้าของของ)
/// - โหลดรายการ:  GET   /api/borrows/lending
/// - ยืนยันคืน:    PATCH /api/borrows/:id/confirm-return
class RequestsReturnsController extends ChangeNotifier {
  RequestsReturnsController({http.Client? client, Authservice? authService})
    : _client = client ?? http.Client(),
      _authService = authService ?? Authservice();

  final http.Client _client;
  final Authservice _authService;

  List<BorrowModel> items = const [];
  bool loading = false;
  String? error;

  /// Unpaid/new requests waiting on borrower payment, plus returns awaiting owner confirm.
  List<BorrowModel> get waitingForResponse => items
      .where(
        (b) =>
            (b.status == 'requested' && b.paymentStatus == 'unpaid') ||
            b.status == 'returned_pending',
      )
      .toList();

  List<BorrowModel> get borrowedItems =>
      items.where((b) => b.status == 'borrowed').toList();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final token = await _authService.loadToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };
      final response = await _client.get(
        Uri.parse('http://localhost:3000/api/borrows/lending'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _dataFrom(response);
        // เอาค่าใน data ของ backend มาแปลงเป็น BorrowModel ใส่ลิสต์
        items = data is List
            ? data
                  .whereType<Map<String, dynamic>>()
                  .map(BorrowModel.fromJson)
                  .toList()
            : <BorrowModel>[];
      } else {
        error = _messageFrom(response, 'Unable to load requests');
      }
    } on Exception {
      error = 'Connection error';
    }

    loading = false;
    notifyListeners();
  }

  /// คืน null เมื่อยืนยันสำเร็จ ไม่งั้นคืนข้อความ error (หน้าจอเอาไปแสดงใน SnackBar)
  Future<String?> confirmReturn(int borrowId) async {
    final index = items.indexWhere((item) => item.id == borrowId);
    if (index == -1) return 'Borrow not found';
    final borrow = items[index];
    if (borrow.status != 'returned_pending') {
      return 'Return has not been requested';
    }

    try {
      final token = await _authService.loadToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };
      if (token == null || token.isEmpty) return 'Please log in again';

      final response = await _client.patch(
        Uri.parse('http://localhost:3000/api/borrows/$borrowId/confirm-return'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final updated = List<BorrowModel>.of(items);
        updated[index] = borrow.copyWith(status: 'returned_confirmed');
        items = updated;
        notifyListeners();
        return null;
      }
      return _messageFrom(response, 'Unable to confirm return');
    } on Exception {
      return 'Connection error';
    }
  }

  /// ดึงข้อความ error จาก body รูปแบบ { "message": "..." } ของ backend
  String _messageFrom(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // body ไม่ใช่ JSON ใช้ข้อความสำรอง
    }
    return fallback;
  }

  /// ดึงฟิลด์ "data" จาก response รูปแบบ { "data": ... }
  dynamic _dataFrom(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return decoded['data'];
    } catch (_) {
      // body ไม่ใช่ JSON
    }
    return null;
  }
}
