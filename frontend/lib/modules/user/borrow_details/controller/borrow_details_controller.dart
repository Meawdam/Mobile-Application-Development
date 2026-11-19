import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/services/auth_service.dart';

// สถานะของแต่ละขั้นใน Status timeline
// done = เสร็จแล้ว (เขียว), inProgress = กำลังดำเนินการ (เหลือง), notStarted = ยังไม่ถึง (เทา)
enum TimelineStepState { done, inProgress, notStarted }

// Controller หน้า Borrow Details (ฝั่งผู้ยืม)
//
// API ที่เชื่อม (ทั้งหมดมีใน backend แล้ว ต้องล็อกอินก่อน เพราะใช้ token จาก Authservice):
//   GET   /api/borrows/{id}                  ดึงรายละเอียดการยืม -> load()
//   PATCH /api/borrows/{id}/confirm-received กดว่า "ได้รับของแล้ว" (Received) -> confirmReceived()
//   PATCH /api/borrows/{id}/return           กด Request return -> requestReturn()
//   PATCH /api/borrows/{id}/confirm-return   เจ้าของกด Confirm return -> confirmReturn()
//
// ข้อสังเกตเรื่อง backend:
//   - confirm-received: backend ยอมให้กดได้ทั้งที่เจ้าของยังไม่อนุมัติ
//     แต่ตาม flow หน้าจอจะแสดงปุ่ม Received เมื่อจ่ายแล้วและเจ้าของอนุมัติแล้ว (approved) เท่านั้น
//     เมื่อกดแล้ว backend จะเปลี่ยน status เป็น borrowed ให้
//   - confirm-return ทำได้เฉพาะเจ้าของสินค้า ถ้าผู้ยืมกดจะได้ error 403 จาก backend
class BorrowDetailsController extends ChangeNotifier {
  BorrowDetailsController({Authservice? service})
    : authService = service ?? Authservice();

  final Authservice authService;

  BorrowModel? borrow;
  bool loading = false;
  String? error;

  // ชื่อแต่ละขั้นของ Status timeline ตามลำดับที่แสดง
  static const List<String> timelineLabels = [
    'Paid',
    'Received',
    'Borrowed',
    'Returned',
  ];

  // ส่ง request พร้อม token (รูปแบบเดียวกับ LoginController: เรียก http ตรงๆ)
  Future<http.Response> _send(String method, String path) async {
    final token = await authService.loadToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('http://localhost:3000$path');

    try {
      if (method == 'GET') return await http.get(uri, headers: headers);
      return await http.patch(uri, headers: headers);
    } on Exception {
      throw Exception('Connection error');
    }
  }

  // อ่านข้อความ error จาก response ของ backend ({ "message": "..." })
  String _messageOf(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } on FormatException {
      // ใช้ข้อความมาตรฐานด้านล่างแทน
    }
    return 'Request failed (${response.statusCode})';
  }

  // โหลดรายละเอียดการยืม: GET /api/borrows/{id}
  Future<void> load(int borrowId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _send('GET', '/api/borrows/$borrowId');
      if (response.statusCode != 200) {
        borrow = null;
        error = _messageOf(response);
      } else {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic> ||
            decoded['data'] is! Map<String, dynamic>) {
          throw const FormatException('Invalid borrow response');
        }
        borrow = BorrowModel.fromJson(decoded['data'] as Map<String, dynamic>);
      }
    } on Exception catch (e) {
      borrow = null;
      error = e.toString().replaceFirst('Exception: ', '');
    }

    loading = false;
    notifyListeners();
  }

  // จ่ายเงินแล้วแต่ยังไม่กด Received (แสดงปุ่ม Received)
  bool get canConfirmReceived {
    final b = borrow;
    return b != null && b.paymentStatus == 'paid' && b.status == 'approved';
  }

  bool get canCancelRequest {
    final b = borrow;
    return b != null &&
        (b.status == 'requested' || b.status == 'approved') &&
        (b.paymentStatus == 'unpaid' || b.paymentStatus == 'paid');
  }

  Future<String?> cancelRequest() async {
    final current = borrow;
    if (current == null) return 'Missing borrow';
    if (!canCancelRequest) return 'This request can no longer be cancelled';
    return _patchThenReload('/api/borrows/${current.id}/cancel');
  }

  // สถานะของ 4 ขั้นใน timeline: Paid, Received, Borrowed, Returned
  // ขั้นที่เสร็จ = เขียว, ขั้นแรกที่ยังไม่เสร็จ = เหลือง, ขั้นหลังจากนั้น = เทา
  List<TimelineStepState> get timeline {
    final b = borrow;
    if (b == null || b.status == 'cancelled' || b.status == 'rejected') {
      return List.filled(4, TimelineStepState.notStarted);
    }

    final afterReturn =
        b.status == 'returned_pending' || b.status == 'returned_confirmed';
    final received = b.status == 'borrowed' || afterReturn;
    final done = [
      b.paymentStatus != 'unpaid', // Paid
      received, // Received
      afterReturn, // Borrowed (ช่วงยืมจบเมื่อแจ้งคืนแล้ว)
      b.status == 'returned_confirmed', // Returned
    ];

    final firstPending = done.indexOf(false);
    return [
      for (var i = 0; i < done.length; i++)
        done[i]
            ? TimelineStepState.done
            : (i == firstPending
                  ? TimelineStepState.inProgress
                  : TimelineStepState.notStarted),
    ];
  }

  // กดปุ่ม Received: PATCH /api/borrows/{id}/confirm-received
  Future<String?> confirmReceived() async {
    final current = borrow;
    if (current == null) return 'Missing borrow';
    if (!canConfirmReceived) {
      return 'Pay for this borrow before confirming receipt';
    }
    return _patchThenReload('/api/borrows/${current.id}/confirm-received');
  }

  // กดปุ่ม Request return: PATCH /api/borrows/{id}/return
  Future<String?> requestReturn() async {
    final current = borrow;
    if (current == null) return 'Missing borrow';
    if (current.status != 'borrowed') return 'Borrow is not active';
    return _patchThenReload('/api/borrows/${current.id}/return');
  }

  // กดปุ่ม Confirm return (เจ้าของ): PATCH /api/borrows/{id}/confirm-return
  Future<String?> confirmReturn() async {
    final current = borrow;
    if (current == null) return 'Missing borrow';
    if (current.status != 'returned_pending') {
      return 'Return has not been requested';
    }
    return _patchThenReload('/api/borrows/${current.id}/confirm-return');
  }

  // เรียก PATCH แล้วโหลดรายละเอียดใหม่เมื่อสำเร็จ
  Future<String?> _patchThenReload(String path) async {
    final id = borrow!.id;
    try {
      final response = await _send('PATCH', path);
      if (response.statusCode != 200) return _messageOf(response);
    } on Exception catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    await load(id);
    return null;
  }
}
