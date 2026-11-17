import 'dart:convert';


import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


import '../../../../services/auth_service.dart';
import '../model/approve_item_model.dart';
import '../../admin_time.dart';


class ApproveItemsController extends ChangeNotifier {
  static const String _baseUrl = 'http://localhost:3000';


  final Authservice _authService = Authservice();
  final List<ApproveItem> _items = [];


  bool _isLoading = false;
  String? _errorMessage;


  List<ApproveItem> get items => List.unmodifiable(_items);
  int get pendingCount => _items.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  // โหลดรายการที่รออนุมัติ
  Future<void> fetchItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();


    try {
      final token = await _getToken();


      final response = await http.get(
        Uri.parse('$_baseUrl/api/assets/all'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 15));


      if (response.statusCode != 200) {
        throw Exception(_getErrorMessage(response));
      }


      final decoded = jsonDecode(response.body);


      if (decoded is! Map || decoded['data'] is! List) {
        throw Exception('The item data format is incorrect.');
      }


      final allItems = (decoded['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();


      _items
        ..clear()
        ..addAll(
          allItems
              .where((item) =>
                  item['approval']?.toString().toLowerCase() == 'pending')
              .map(
                (item) => ApproveItem.fromMap({
                  'id': item['id']?.toString() ?? '',
                  'name': item['name']?.toString() ?? '-',
                  'owner': item['owner_username']?.toString() ??
                      item['username']?.toString() ??
                      '-',
                  'time': formatAdminTime(item['created_at']?.toString() ??
                      item['submitted_at']?.toString() ??
                      '-'),
                  'description': item['description']?.toString() ?? '',
                }),
              ),
        );
    } catch (e) {
      _errorMessage = _cleanError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // อนุมัติรายการ
  Future<bool> approveItem(String id) {
    return _updateApproval(
      id: id,
      approval: 'approved',
    );
  }


  // ปฏิเสธรายการ
  Future<bool> rejectItem(String id, String reason) {
    final trimmedReason = reason.trim();


    if (trimmedReason.isEmpty) {
      _errorMessage = 'Please provide a reason for the rejection.';
      notifyListeners();
      return Future.value(false);
    }


    if (trimmedReason.length > 500) {
      _errorMessage = 'The reason must not exceed 500 characters.';
      notifyListeners();
      return Future.value(false);
    }


    return _updateApproval(
      id: id,
      approval: 'not approve',
      reason: trimmedReason,
    );
  }


  // ส่งคำขออนุมัติหรือปฏิเสธไป Backend
  Future<bool> _updateApproval({
    required String id,
    required String approval,
    String? reason,
  }) async {
    try {
      final token = await _getToken();


      final body = <String, dynamic>{
        'approval': approval,
      };


      if (reason != null) {
        body['approval_message'] = reason;
      }


      final response = await http.patch(
        Uri.parse('$_baseUrl/api/assets/$id/approve'),
        headers: _headers(token),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));


      if (response.statusCode != 200) {
        throw Exception(_getErrorMessage(response));
      }


      _items.removeWhere((item) => item.id == id);


      _errorMessage = null;
      notifyListeners();


      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      notifyListeners();
      return false;
    }
  }


  Future<String> _getToken() async {
    final token = await _authService.loadToken();


    if (token == null || token.isEmpty) {
      throw Exception('Token not found. Please log in again.');
    }


    return token;
  }


  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }


  String _getErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);


      if (decoded is Map) {
        return decoded['message']?.toString() ??
            'An error occurred. (${response.statusCode})';
      }
    } catch (_) {
      // ใช้ข้อความสำรองเมื่อ Response ไม่ใช่ JSON
    }


    return 'An error occurred. (${response.statusCode})';
  }


  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
