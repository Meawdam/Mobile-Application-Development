import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/services/auth_service.dart';

// Controller หน้า My Borrowed Items (ฝั่งผู้ยืม)
//
// API ที่เชื่อม (ทั้งหมดมีใน backend แล้ว ต้องล็อกอินก่อน เพราะใช้ token จาก Authservice):
//   GET   /api/borrows/my           ดึงรายการที่ฉันยืมทั้งหมด -> load()
//   PATCH /api/borrows/{id}/cancel  กด Cancel ในแท็บ Pending -> cancel()
//                                   backend ยกเลิกแล้วคืนเงินค่าเช่า+เงินมัดจำเข้ากระเป๋าอัตโนมัติ
//   PATCH /api/borrows/{id}/return  กด Request return -> requestReturn()
//
// Flow: ผู้ยืมจ่ายเงินทันทีตอนขอยืม -> รายการอยู่ Pending รอเจ้าของอนุมัติ
//       -> เจ้าของอนุมัติแล้วรายการย้ายไป Borrowing (กด Received ในหน้า details)
class MyBorrowedController extends ChangeNotifier {
  MyBorrowedController({List<BorrowModel>? initialItems, Authservice? service})
    : items = List.of(initialItems ?? const []),
      authService = service ?? Authservice();

  final Authservice authService;

  List<BorrowModel> items;
  bool loading = false;
  String? error;

  // เงินมัดจำที่ยังถูกถือไว้ = จ่ายแล้ว และรายการยังไม่จบ (ยังไม่คืนเสร็จ/ไม่ถูกยกเลิก)
  num get heldDeposit => items
      .where(
        (b) =>
            b.paymentStatus == 'paid' &&
            b.status != 'returned_confirmed' &&
            b.status != 'cancelled' &&
            b.status != 'rejected',
      )
      .fold<num>(0, (sum, b) => sum + (b.deposit ?? 0));

  // แท็บ Borrowing: เจ้าของอนุมัติแล้ว / กำลังยืม / แจ้งคืนแล้วรอเจ้าของยืนยัน
  List<BorrowModel> get borrowing => items
      .where(
        (b) =>
            b.status == 'approved' ||
            b.status == 'borrowed' ||
            b.status == 'returned_pending',
      )
      .toList();

  // แท็บ Pending: จ่ายเงินแล้ว รอเจ้าของอนุมัติ (กด Cancel ได้)
  List<BorrowModel> get pending =>
      items.where((b) => b.status == 'requested').toList();

  // แท็บ Returned: คืนเรียบร้อยแล้ว
  List<BorrowModel> get returned =>
      items.where((b) => b.status == 'returned_confirmed').toList();

  List<BorrowModel> get history => items
      .where((b) => b.status == 'cancelled' || b.status == 'rejected')
      .toList();

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

  // โหลดรายการที่ฉันยืม: GET /api/borrows/my
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _send('GET', '/api/borrows/my');
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

  // กด Cancel ในแท็บ Pending: PATCH /api/borrows/{id}/cancel
  // คืนค่า null เมื่อสำเร็จ หรือข้อความ error
  Future<String?> cancel(int borrowId) async {
    final index = items.indexWhere((item) => item.id == borrowId);
    if (index == -1) return 'Borrow not found';
    final borrow = items[index];
    if (borrow.status != 'requested' && borrow.status != 'approved') {
      return 'Only requests awaiting receipt can be cancelled';
    }
    return _patchThenReload('/api/borrows/$borrowId/cancel');
  }

  // กด Request return ในแท็บ Borrowing: PATCH /api/borrows/{id}/return
  Future<String?> requestReturn(int borrowId) async {
    final index = items.indexWhere((item) => item.id == borrowId);
    if (index == -1) return 'Borrow not found';
    if (items[index].status != 'borrowed') return 'Borrow is not active';
    return _patchThenReload('/api/borrows/$borrowId/return');
  }

  // เรียก PATCH แล้วโหลดรายการใหม่เมื่อสำเร็จ
  Future<String?> _patchThenReload(String path) async {
    try {
      final response = await _send('PATCH', path);
      if (response.statusCode != 200) return _messageOf(response);
    } on Exception catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    await load();
    return null;
  }
}
