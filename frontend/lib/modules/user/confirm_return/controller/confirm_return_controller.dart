import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/services/api_helper.dart';
import 'package:frontend/services/auth_service.dart';
import '../../shared/model/lending_item_model.dart';
import '../../shared/model/return_request_model.dart';

/// ผลของการยืนยันรับของคืน: success=สำเร็จ, notFound=ไม่พบคำขอ,
/// forbidden=ไม่ใช่เจ้าของ, alreadyConfirmed=ยืนยันไปแล้ว,
/// notRequested=ผู้ยืมยังไม่ได้แจ้งคืน, failed=เรียก backend ไม่สำเร็จ
enum ConfirmReturnResult {
  success,
  notFound,
  forbidden,
  alreadyConfirmed,
  notRequested,
  failed,
}

/// ควบคุมหน้ายืนยันรับของคืน: เจ้าของกดยืนยันว่าได้ของคืนแล้ว
/// - โหลดรายการ:  GET   /api/borrows/lending
/// - ยืนยันคืน:    PATCH /api/borrows/:id/confirm-return
/// กฎตรงกับ backend: ต้องเป็นเจ้าของ และสถานะต้องเป็น returned_pending
class ConfirmReturnController extends ChangeNotifier {
  ConfirmReturnController(
    List<ReturnRequest> requests, {
    required this.currentUserId,
    List<LendingItem> lendingItems = const [],
    http.Client? client,
    Authservice? authService,
  }) : _requests = List.of(requests),
       _lendingItems = List.of(lendingItems),
       _client = client ?? http.Client(),
       _authService = authService ?? Authservice();

  final String currentUserId;
  final List<ReturnRequest> _requests;
  final List<LendingItem> _lendingItems;
  final http.Client _client;
  final Authservice _authService;

  bool loading = false;
  String? error;

  List<ReturnRequest> get requests => List.unmodifiable(_requests);
  List<LendingItem> get lendingItems => List.unmodifiable(_lendingItems);

  /// คำขอของเราที่ผู้ยืมแจ้งคืนแล้วและรอยืนยัน
  List<ReturnRequest> get awaitingConfirmation => _requests
      .where((r) => r.ownerId == currentUserId && r.isAwaitingConfirmation)
      .toList();

  /// จำนวนคำขอที่รอยืนยัน
  int get awaitingCount => awaitingConfirmation.length;

  /// ค่าปรับรวมจากคำขอที่ยืนยันการคืนแล้ว
  int get totalFinesCollected => _requests
      .where(
        (r) =>
            r.ownerId == currentUserId &&
            r.status == BorrowStatus.returnedConfirmed,
      )
      .fold(0, (sum, r) => sum + r.fineAmount);

  /// โหลดรายการยืมของไอเทมที่เราเป็นเจ้าของ จาก GET /api/borrows/lending
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
        _requests
          ..clear()
          ..addAll(
            data is List
                ? data.whereType<Map<String, dynamic>>().map(
                    // รายการนี้เป็นของเราเองอยู่แล้ว backend ไม่ส่ง owner_id มา
                    (m) => ReturnRequest.fromMap({
                      ...m,
                      'owner_id': m['owner_id'] ?? currentUserId,
                    }),
                  )
                : const <ReturnRequest>[],
          );
      } else {
        error = apiMessage(response, 'Unable to load requests');
      }
    } on Exception {
      error = 'Connection error';
    }

    loading = false;
    notifyListeners();
  }

  /// ยืนยันรับของคืน คืนผลเป็น ConfirmReturnResult
  Future<ConfirmReturnResult> confirmReturn(String requestId) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return ConfirmReturnResult.notFound;

    final request = _requests[index];
    if (request.ownerId != currentUserId) return ConfirmReturnResult.forbidden;
    if (request.status == BorrowStatus.returnedConfirmed) {
      return ConfirmReturnResult.alreadyConfirmed;
    }
    if (request.status != BorrowStatus.returnedPending) {
      return ConfirmReturnResult.notRequested;
    }

    error = null;
    var result = ConfirmReturnResult.failed;
    try {
      final headers = await apiHeaders(_authService);
      if (!hasToken(headers)) {
        error = 'Please log in again';
      } else {
        final response = await _client.patch(
          Uri.parse('$apiBaseUrl/api/borrows/$requestId/confirm-return'),
          headers: headers,
        );

        switch (response.statusCode) {
          case 200:
            result = ConfirmReturnResult.success;
          case 403:
            result = ConfirmReturnResult.forbidden;
          case 404:
            result = ConfirmReturnResult.notFound;
          case 400:
            final message = apiMessage(response, '');
            result = message.toLowerCase().contains('already')
                ? ConfirmReturnResult.alreadyConfirmed
                : ConfirmReturnResult.notRequested;
          case 409:
            result = ConfirmReturnResult.notRequested;
          default:
            error = apiMessage(response, 'Unable to confirm return');
        }
      }
    } on Exception {
      error = 'Connection error';
    }

    if (result == ConfirmReturnResult.success) {
      _requests[index] = request.copyWith(
        status: BorrowStatus.returnedConfirmed,
      );
      final lendingIndex = _lendingItems.indexWhere(
        (i) => i.id == request.assetId,
      );
      if (lendingIndex != -1) {
        _lendingItems[lendingIndex] = _lendingItems[lendingIndex].copyWith(
          status: ItemStatus.ready,
        );
      }
    }
    notifyListeners();
    return result;
  }
}
