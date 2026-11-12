import 'package:flutter/foundation.dart';

import '../../shared/model/lending_item_model.dart';
import '../../shared/model/return_request_model.dart';

/// ผลของการยืนยันรับของคืน: success=สำเร็จ, notFound=ไม่พบคำขอ,
/// forbidden=ไม่ใช่เจ้าของ, alreadyConfirmed=ยืนยันไปแล้ว,
/// notRequested=ผู้ยืมยังไม่ได้แจ้งคืน
enum ConfirmReturnResult {
  success,
  notFound,
  forbidden,
  alreadyConfirmed,
  notRequested,
}

/// ควบคุมหน้ายืนยันรับของคืน: เจ้าของกดยืนยันว่าได้ของคืนแล้ว
/// กฎตรงกับ backend: ต้องเป็นเจ้าของ และสถานะต้องเป็น returned_pending
class ConfirmReturnController extends ChangeNotifier {
  ConfirmReturnController(
    List<ReturnRequest> requests, {
    required this.currentUserId,
    List<LendingItem> lendingItems = const [],
  }) : _requests = List.of(requests),
       _lendingItems = List.of(lendingItems);

  final String currentUserId;
  final List<ReturnRequest> _requests;
  final List<LendingItem> _lendingItems;

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

  /// ยืนยันรับของคืน คืนผลเป็น ConfirmReturnResult
  ConfirmReturnResult confirmReturn(String requestId) {
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

    _requests[index] = request.copyWith(status: BorrowStatus.returnedConfirmed);

    final lendingIndex =
        _lendingItems.indexWhere((i) => i.id == request.assetId);
    if (lendingIndex != -1) {
      _lendingItems[lendingIndex] =
          _lendingItems[lendingIndex].copyWith(status: ItemStatus.ready);
    }

    notifyListeners();
    return ConfirmReturnResult.success;
  }
}
