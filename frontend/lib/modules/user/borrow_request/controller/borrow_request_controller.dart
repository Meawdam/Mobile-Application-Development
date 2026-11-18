import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/date_utils.dart';

// Controller หน้า Borrow Request (ฝั่งผู้ยืม)
//
// API ที่เชื่อม (ทั้งหมดมีใน backend แล้ว ต้องล็อกอินก่อน เพราะใช้ token จาก Authservice):
//   GET  /api/assets/{id}  ดึงข้อมูลสินค้ามาแสดง -> load()
//   POST /api/borrows      กด Continue to payment -> สร้างคำขอยืม -> submitRequest()
//                          body: {"asset_id", "pickup_date", "return_date"} (รูปแบบ YYYY-MM-DD)
//
// ข้อสังเกตเรื่อง backend:
//   - backend คำนวณค่าเช่าและยอดรวมเองตอนสร้างคำขอ (ราคา x จำนวนวันแบบนับวันแรกและวันสุดท้าย)
//     ค่าที่หน้าจอคำนวณเป็นแค่ตัวอย่างให้ผู้ใช้เห็นก่อนกดยืนยัน
//   - การจ่ายเงิน (POST /api/borrows/{id}/pay) เป็นหน้า Payment ซึ่งสมาชิกอื่นทำ
class BorrowRequestController extends ChangeNotifier {
  BorrowRequestController({Authservice? service})
    : authService = service ?? Authservice();

  final Authservice authService;
  AssetModel? _asset;
  bool _loading = false;
  bool _submitting = false;
  String? _error;
  DateTime? _pickupDate;
  DateTime? _returnDate;

  AssetModel? get asset => _asset;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  DateTime? get pickupDate => _pickupDate;
  DateTime? get returnDate => _returnDate;

  DateTime? get lendingEndDate =>
      AppDateUtils.tryParseYmd(_asset?.returnBefore);

  DateTime get earliestPickup => AppDateUtils.today();

  bool get datesValid {
    final end = lendingEndDate;
    final currentAsset = _asset;
    if (currentAsset == null ||
        (currentAsset.status != 'available' &&
            currentAsset.status != 'ready') ||
        currentAsset.approval != 'approved' ||
        _pickupDate == null ||
        _returnDate == null ||
        end == null) {
      return false;
    }
    if (_returnDate!.isBefore(_pickupDate!)) return false;
    if (_pickupDate!.isBefore(earliestPickup)) return false;
    if (_pickupDate!.isAfter(end) || _returnDate!.isAfter(end)) return false;
    return true;
  }

  int get rentalDayCount {
    if (_pickupDate == null || _returnDate == null) return 0;
    return AppDateUtils.rentalDays(_pickupDate!, _returnDate!);
  }

  num get rentalSubtotal {
    final price = _asset?.price ?? 0;
    return price * rentalDayCount;
  }

  num get deposit => _asset?.downPayment ?? 0;

  num get total => rentalSubtotal + deposit;

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
      return await http.post(uri, headers: headers, body: jsonEncode(body));
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

  // โหลดข้อมูลสินค้า: GET /api/assets/{id}
  Future<void> load(int assetId) async {
    _loading = true;
    _error = null;
    _asset = null;
    _pickupDate = null;
    _returnDate = null;
    notifyListeners();

    try {
      final response = await _send('GET', '/api/assets/$assetId');
      if (response.statusCode != 200) {
        _error = _messageOf(response);
      } else {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic> ||
            decoded['data'] is! Map<String, dynamic>) {
          throw const FormatException('Invalid asset response');
        }
        _asset = AssetModel.fromJson(decoded['data'] as Map<String, dynamic>);

        if ((_asset!.status != 'available' && _asset!.status != 'ready') ||
            _asset!.approval != 'approved') {
          _error = 'Item is not available for borrowing';
        } else {
          final end = lendingEndDate;
          if (end == null || end.isBefore(earliestPickup)) {
            _error = 'This item has no valid lending end date';
          }
        }
      }
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _loading = false;
    notifyListeners();
  }

  void setPickupDate(DateTime date) {
    final end = lendingEndDate;
    if (end == null) return;

    final picked = AppDateUtils.dateOnly(date);
    if (!AppDateUtils.isWithinRange(
      picked,
      first: earliestPickup,
      last: end,
    )) {
      return;
    }

    _pickupDate = picked;
    if (_returnDate != null && _returnDate!.isBefore(picked)) {
      _returnDate = null;
    }
    if (_returnDate != null && _returnDate!.isAfter(end)) {
      _returnDate = null;
    }
    notifyListeners();
  }

  void setReturnDate(DateTime date) {
    final end = lendingEndDate;
    if (end == null || _pickupDate == null) return;

    final picked = AppDateUtils.dateOnly(date);
    if (!AppDateUtils.isWithinRange(
      picked,
      first: _pickupDate!,
      last: end,
    )) {
      return;
    }

    _returnDate = picked;
    notifyListeners();
  }

  // กด Continue to payment: POST /api/borrows แล้วคืน BorrowModel ของคำขอที่สร้าง (null ถ้าไม่สำเร็จ)
  Future<BorrowModel?> submitRequest() async {
    final asset = _asset;
    if (!datesValid || asset == null) {
      _error = 'Choose pickup and return dates within the lender timeframe';
      notifyListeners();
      return null;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    BorrowModel? created;
    try {
      final response = await _send(
        'POST',
        '/api/borrows',
        body: {
          'asset_id': asset.id,
          'pickup_date': AppDateUtils.formatYmd(_pickupDate!),
          'return_date': AppDateUtils.formatYmd(_returnDate!),
        },
      );
      if (response.statusCode != 201) {
        _error = _messageOf(response);
      } else {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic> ||
            decoded['data'] is! Map<String, dynamic>) {
          throw const FormatException('Invalid borrow response');
        }
        final data = BorrowModel.fromJson(decoded['data'] as Map<String, dynamic>);
        // response ของ POST ไม่มีชื่อสินค้า/เจ้าของ จึงเติมจากข้อมูลสินค้าที่โหลดไว้
        created = BorrowModel(
          id: data.id,
          assetId: data.assetId,
          assetName: asset.name,
          ownerName: asset.ownerUsername,
          pickupPoint: asset.pickupPoint,
          pickupDate: data.pickupDate,
          plannedReturnDate: data.plannedReturnDate,
          rentalDays: data.rentalDays,
          lendingEndDate: data.lendingEndDate,
          pricePerDay: data.pricePerDay,
          rentalSubtotal: data.rentalSubtotal,
          deposit: data.deposit,
          totalAmount: data.totalAmount,
          status: data.status,
          paymentStatus: data.paymentStatus,
        );
      }
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _submitting = false;
    notifyListeners();
    return created;
  }
}
