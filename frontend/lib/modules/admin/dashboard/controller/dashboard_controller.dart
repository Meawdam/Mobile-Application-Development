import 'dart:convert';


import 'package:http/http.dart' as http;


import '../../../../services/auth_service.dart';
import '../model/dashboard_model.dart';


class DashboardController {
  static const String _baseUrl = 'http://localhost:3000';


  final Authservice _authService = Authservice();


  // ดึงข้อมูล Dashboard จาก Backend
  Future<DashboardStats> fetchDashboardStats() async {
    final token = await _authService.loadToken();


    if (token == null || token.isEmpty) {
      throw Exception('Token not found. Please log in again.');
    }


    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/admin/dashboard'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));


      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);


        if (decoded is! Map<String, dynamic>) {
          throw Exception('The dashboard data format is incorrect.');
        }


        final data = decoded['data'];


        if (data is! Map<String, dynamic>) {
          throw Exception('No dashboard data found');
        }


        final assets = data['assets'];


        if (assets is! Map<String, dynamic>) {
          throw Exception('No asset statistics found.');
        }


        return DashboardStats(
          approvedCount: _toInt(assets['approved']),
          pendingCount: _toInt(assets['pending']),
          borrowedCount: _toInt(assets['borrowed']),
        );
      }


      if (response.statusCode == 401 ||
          response.statusCode == 403) {
        throw Exception(
          'No access to the dashboard; please check the admin token.',
        );
      }


      throw Exception(
        'Failed to load dashboard (${response.statusCode}): ${response.body}',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to connect to the backend: $e');
    }
  }


  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }


  bool hasPendingRequests(int pendingCount) {
    return pendingCount > 0;
  }
}