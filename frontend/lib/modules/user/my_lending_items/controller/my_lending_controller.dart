import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/services/auth_service.dart';

/// หน้า My Lending Items
/// - โหลดรายการของฉัน: GET    /api/assets/mine
/// - ลบไอเทม:          DELETE /api/assets/:id
class MyLendingController extends ChangeNotifier {
  MyLendingController({http.Client? client, Authservice? authService})
    : _client = client ?? http.Client(),
      _authService = authService ?? Authservice();

  final http.Client _client;
  final Authservice _authService;

  List<AssetModel> items = const [];
  bool loading = false;
  String? error;

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
        Uri.parse('http://localhost:3000/api/assets/mine'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _dataFrom(response);
        // เอาค่าใน data ของ backend มาแปลงเป็น AssetModel ใส่ลิสต์
        items = data is List
            ? data
                  .whereType<Map<String, dynamic>>()
                  .map(AssetModel.fromJson)
                  .toList()
            : <AssetModel>[];
      } else {
        error = _messageFrom(response, 'Unable to load items');
      }
    } on Exception {
      error = 'Connection error';
    }

    loading = false;
    notifyListeners();
  }

  /// คืน null เมื่อลบสำเร็จ ไม่งั้นคืนข้อความ error (หน้าจอเอาไปแสดงใน SnackBar)
  Future<String?> deleteAsset(int id) async {
    try {
      final token = await _authService.loadToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };
      if (token == null || token.isEmpty) return 'Please log in again';

      final response = await _client.delete(
        Uri.parse('http://localhost:3000/api/assets/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        items = items.where((asset) => asset.id != id).toList();
        notifyListeners();
        return null;
      }
      return _messageFrom(response, 'Unable to delete item');
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
