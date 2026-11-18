import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/services/api_helper.dart';
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
      final headers = await apiHeaders(_authService);
      final response = await _client.get(
        Uri.parse('$apiBaseUrl/api/assets/mine'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = apiData(response);
        // เอาค่าใน data ของ backend มาแปลงเป็น AssetModel ใส่ลิสต์
        items = data is List
            ? data
                  .whereType<Map<String, dynamic>>()
                  .map(AssetModel.fromJson)
                  .toList()
            : <AssetModel>[];
      } else {
        error = apiMessage(response, 'Unable to load items');
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
      final headers = await apiHeaders(_authService);
      if (!hasToken(headers)) return 'Please log in again';

      final response = await _client.delete(
        Uri.parse('$apiBaseUrl/api/assets/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        items = items.where((asset) => asset.id != id).toList();
        notifyListeners();
        return null;
      }
      return apiMessage(response, 'Unable to delete item');
    } on Exception {
      return 'Connection error';
    }
  }
}
