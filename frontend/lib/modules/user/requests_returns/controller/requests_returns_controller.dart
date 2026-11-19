import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/services/auth_service.dart';

// Controller หน้า Requests & Returns (ฝั่งเจ้าของสินค้า)
//
// API ที่เชื่อม (ทั้งหมดมีใน backend แล้ว ต้องล็อกอินก่อน เพราะใช้ token จาก Authservice):
//   GET   /api/borrows/owner               ดึงรายการยืมของสินค้าที่ฉันเป็นเจ้าของ -> load()
//   PATCH /api/borrows/{id}/approve        กด Approve -> approve()
//   PATCH /api/borrows/{id}/reject         กด Reject (ต้องส่ง reason) -> reject()
//   PATCH /api/borrows/{id}/confirm-return กด Confirm (ยืนยันรับของคืน) -> confirmReturn()
//
// ข้อสังเกตเรื่อง backend (ควรตกลงกับคนทำ backend):
//   - Flow: ผู้ยืมจ่ายเงินก่อน แล้วเจ้าของจึงกด Approve/Reject
//     แต่ backend (borrow_service.js _decideRequest และ borrow_repository.js decideRequest)
//     ยังอนุญาต approve/reject เฉพาะคำขอที่ยังไม่จ่าย (payment_status = unpaid)
//     จึงได้ error "Borrow request is no longer awaiting a decision" ต้องให้เพื่อนแก้ backend
//   - reject คำขอที่จ่ายแล้ว backend ยังไม่คืนเงินให้ผู้ยืม (ต้องเพิ่มการคืนเงินใน backend)
//   - reject ต้องส่งเหตุผล (reason ไม่เกิน 500 ตัวอักษร) หน้าจอจึงมีช่องให้กรอกเหตุผล
//   - ผู้ยืมที่ยกเลิกคำขอ backend เก็บเป็น status 'cancelled' (แยกจาก 'rejected' แล้ว)
class RequestsReturnsController extends ChangeNotifier {
  RequestsReturnsController({
    List<BorrowModel>? initialItems,
    Authservice? service,
  }) : items = List.of(initialItems ?? const []),
       authService = service ?? Authservice();

  final Authservice authService;

  List<BorrowModel> items;
  bool loading = false;
  String? error;

  // ส่วน Waiting for Response: คำขอที่รอเจ้าของตอบ และคำขอที่ผู้ยืมกดยกเลิกไปแล้ว
  List<BorrowModel> get waitingForResponse => items
      .where((b) => b.status == 'requested' || b.status == 'cancelled')
      .toList();

  // ส่วน Borrowed Items: กำลังถูกยืม และผู้ยืมแจ้งคืนแล้วรอเจ้าของ Confirm
  List<BorrowModel> get borrowedItems => items
      .where((b) => b.status == 'borrowed' || b.status == 'returned_pending')
      .toList();

  // ส่ง request พร้อม token (รูปแบบเดียวกับ LoginController: เรียก http ตรงๆ)
  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await authService.loadToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('http://localhost:3000$path');

    try {
      if (method == 'GET') return await http.get(uri, headers: headers);
      return await http.patch(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      );
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

  // โหลดรายการของสินค้าที่ฉันเป็นเจ้าของ: GET /api/borrows/owner
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _send('GET', '/api/borrows/owner');
      if (response.statusCode != 200) {
        error = _messageOf(response);
      } else {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
          throw const FormatException('Invalid borrow list response');
        }
        items = (decoded['data'] as List)
            .map((e) => BorrowModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } on Exception catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }

    loading = false;
    notifyListeners();
  }

  // กด Approve: PATCH /api/borrows/{id}/approve
  // คืนค่า null เมื่อสำเร็จ หรือข้อความ error
  Future<String?> approve(int borrowId) async {
    final index = items.indexWhere((item) => item.id == borrowId);
    if (index == -1) return 'Borrow not found';
    if (items[index].status != 'requested') {
      return 'Request is no longer waiting for a response';
    }
    return _patchThenReload('/api/borrows/$borrowId/approve');
  }

  // กด Reject: PATCH /api/borrows/{id}/reject พร้อมเหตุผล {"reason": "..."}
  Future<String?> reject(int borrowId, String reason) async {
    final index = items.indexWhere((item) => item.id == borrowId);
    if (index == -1) return 'Borrow not found';
    if (items[index].status != 'requested') {
      return 'Request is no longer waiting for a response';
    }
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return 'A reason is required to reject a request';
    if (trimmed.length > 500) return 'Reason must not exceed 500 characters';
    return _patchThenReload(
      '/api/borrows/$borrowId/reject',
      body: {'reason': trimmed},
    );
  }

  // กด Confirm ในส่วน Borrowed Items: PATCH /api/borrows/{id}/confirm-return
  Future<String?> confirmReturn(int borrowId) async {
    final index = items.indexWhere((item) => item.id == borrowId);
    if (index == -1) return 'Borrow not found';
    if (items[index].status != 'returned_pending') {
      return 'Return has not been requested';
    }
    return _patchThenReload('/api/borrows/$borrowId/confirm-return');
  }

  // เรียก PATCH แล้วโหลดรายการใหม่เมื่อสำเร็จ
  Future<String?> _patchThenReload(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _send('PATCH', path, body: body);
      if (response.statusCode != 200) return _messageOf(response);
    } on Exception catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    await load();
    return null;
  }
}
