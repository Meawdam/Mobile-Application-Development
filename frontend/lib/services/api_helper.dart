import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:frontend/services/auth_service.dart';

/// Base URL ของ backend
/// - Chrome/Edge: http://localhost:3000
/// - Android emulator: เปลี่ยนเป็น http://10.0.2.2:3000
const String apiBaseUrl = 'http://localhost:3000';

/// สร้าง header สำหรับเรียก API: ใส่ Authorization: Bearer <token> ให้อัตโนมัติ
/// [json] = true จะใส่ Content-Type เป็น application/json ด้วย
/// (ส่งไฟล์แบบ multipart ให้ใส่ json: false เพื่อให้ http ตั้ง boundary เอง)
Future<Map<String, String>> apiHeaders(
  Authservice authService, {
  bool json = true,
}) async {
  final token = await authService.loadToken();
  return {
    if (json) 'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}

/// header นี้มี token หรือไม่ (ไม่มี = ยังไม่ได้ login)
bool hasToken(Map<String, String> headers) =>
    headers.containsKey('Authorization');

/// ดึงข้อความ error จาก body รูปแบบ { "message": "..." } ของ backend
String apiMessage(http.Response response, String fallback) {
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

/// ดึงฟิลด์ "data" จาก response รูปแบบ { "data": ... } (ไม่มี/อ่านไม่ได้ = null)
dynamic apiData(http.Response response) {
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map) return decoded['data'];
  } catch (_) {
    // body ไม่ใช่ JSON
  }
  return null;
}
