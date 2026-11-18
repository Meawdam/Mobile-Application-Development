import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/date_utils.dart';

enum EditItemResult {
  success,
  missingFields,
  invalidPrice,
  invalidDeposit,
  missingLendingEndDate,
  failed,
}

/// หน้า Edit Item
/// - โหลดข้อมูล: GET   /api/assets/:id
/// - บันทึก:     PATCH /api/assets/:id (JSON, ต้องมี token และเป็นเจ้าของ)
class EditItemController extends ChangeNotifier {
  EditItemController({http.Client? client, Authservice? authService})
    : _client = client ?? http.Client(),
      _authService = authService ?? Authservice();

  final http.Client _client;
  final Authservice _authService;

  AssetModel? asset;
  DateTime? lendingEndDate;
  bool loading = false;
  bool submitting = false;
  String? error;

  Future<void> load(int assetId) async {
    loading = true;
    error = null;
    notifyListeners();
    asset = null;

    try {
      final token = await _authService.loadToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };
      final response = await _client.get(
        Uri.parse('http://localhost:3000/api/assets/$assetId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _dataFrom(response);
        if (data is Map<String, dynamic>) {
          // เอาค่าที่ backend ส่งมาใส่ AssetModel (ฟอร์มจะถูกเติมจากตัวนี้)
          asset = AssetModel.fromJson(data);
          lendingEndDate = AppDateUtils.tryParseYmd(asset!.returnBefore);
        } else {
          error = 'Item not found';
        }
      } else {
        error = _messageFrom(response, 'Item not found');
      }
    } on Exception {
      error = 'Connection error';
    }

    loading = false;
    notifyListeners();
  }

  void setLendingEndDate(DateTime date) {
    lendingEndDate = AppDateUtils.dateOnly(date);
    notifyListeners();
  }

  Future<EditItemResult> save({
    required String name,
    required String description,
    required String price,
    required String deposit,
    required String pickupPoint,
  }) async {
    final current = asset;
    if (current == null) return EditItemResult.failed;

    final trimmedName = name.trim();
    final trimmedDescription = description.trim();
    final trimmedPickup = pickupPoint.trim();
    final trimmedPrice = price.trim();
    final trimmedDeposit = deposit.trim();

    if (trimmedName.isEmpty ||
        trimmedDescription.isEmpty ||
        trimmedPickup.isEmpty ||
        trimmedPrice.isEmpty ||
        trimmedDeposit.isEmpty) {
      return EditItemResult.missingFields;
    }
    final endDate = lendingEndDate;
    if (endDate == null) {
      return EditItemResult.missingLendingEndDate;
    }
    final parsedPrice = int.tryParse(trimmedPrice);
    if (parsedPrice == null || parsedPrice < 0 || parsedPrice > 2147483647) {
      return EditItemResult.invalidPrice;
    }
    final parsedDeposit = num.tryParse(trimmedDeposit);
    if (parsedDeposit == null ||
        !parsedDeposit.isFinite ||
        parsedDeposit < 0) {
      return EditItemResult.invalidDeposit;
    }

    submitting = true;
    error = null;
    notifyListeners();

    var result = EditItemResult.failed;
    try {
      final token = await _authService.loadToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };
      if (token == null || token.isEmpty) {
        error = 'Please log in again';
      } else {
        // body: ฟิลด์ตามที่ Swagger PATCH /api/assets/:id กำหนด
        final response = await _client.patch(
          Uri.parse('http://localhost:3000/api/assets/${current.id}'),
          headers: headers,
          body: jsonEncode({
            'name': trimmedName,
            'description': trimmedDescription,
            'down_payment': parsedDeposit,
            'price': parsedPrice,
            'pickup_point': trimmedPickup,
            'return_before': AppDateUtils.formatYmd(endDate),
          }),
        );

        if (response.statusCode == 200) {
          // เอาค่าที่บันทึกไปใส่ asset ปัจจุบัน
          asset = AssetModel(
            id: current.id,
            ownerId: current.ownerId,
            ownerUsername: current.ownerUsername,
            image: current.image,
            name: trimmedName,
            description: trimmedDescription,
            status: current.status,
            approval: current.approval,
            approvalMessage: current.approvalMessage,
            downPayment: parsedDeposit,
            returnBefore: AppDateUtils.formatYmd(endDate),
            price: parsedPrice,
            pickupPoint: trimmedPickup,
          );
          result = EditItemResult.success;
        } else {
          error = _messageFrom(response, 'Unable to save changes');
        }
      }
    } on Exception {
      error = 'Connection error';
    }

    submitting = false;
    notifyListeners();
    return result;
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
