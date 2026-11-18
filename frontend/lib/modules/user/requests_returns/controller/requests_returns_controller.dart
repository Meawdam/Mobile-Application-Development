import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/services/api_helper.dart';
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
      final headers = await apiHeaders(_authService);
      final response = await _client.get(
        Uri.parse('$apiBaseUrl/api/borrows/lending'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = apiData(response);
        // เอาค่าใน data ของ backend มาแปลงเป็น BorrowModel ใส่ลิสต์
        items = data is List
            ? data
                  .whereType<Map<String, dynamic>>()
                  .map(BorrowModel.fromJson)
                  .toList()
            : <BorrowModel>[];
      } else {
        error = apiMessage(response, 'Unable to load requests');
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
      final headers = await apiHeaders(_authService);
      if (!hasToken(headers)) return 'Please log in again';

      final response = await _client.patch(
        Uri.parse('$apiBaseUrl/api/borrows/$borrowId/confirm-return'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final updated = List<BorrowModel>.of(items);
        updated[index] = borrow.copyWith(status: 'returned_confirmed');
        items = updated;
        notifyListeners();
        return null;
      }
      return apiMessage(response, 'Unable to confirm return');
    } on Exception {
      return 'Connection error';
    }
  }
}
