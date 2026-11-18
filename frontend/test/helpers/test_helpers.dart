import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

/// Authservice จำลอง: ไม่แตะ secure storage จริง คืน token ที่กำหนด
/// ส่ง token: null เพื่อจำลองว่ายังไม่ได้ login
class FakeAuthservice extends Fake implements Authservice {
  FakeAuthservice({this.token = 'test-token'});

  final String? token;

  @override
  Future<String?> loadToken() async => token;
}

/// สร้าง http.Response แบบ JSON เหมือนที่ backend ตอบ
http.Response jsonResponse(Object body, [int status = 200]) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// ข้อมูล asset หนึ่งชิ้นในรูปแบบเดียวกับที่ backend ส่งมา (GET /api/assets/...)
Map<String, dynamic> assetJson({
  int id = 1,
  String name = 'My camera',
  String status = 'ready',
  String approval = 'approved',
}) {
  return {
    'id': id,
    'owner_id': 17,
    'owner_username': 'sample_user',
    'image': null,
    'name': name,
    'description': 'Digital camera',
    'status': status,
    'approval': approval,
    'approval_message': null,
    'down_payment': 500,
    'return_before': '2030-01-01',
    'price': 120,
    'pickup_point': 'Canteen',
  };
}

/// ข้อมูล borrow หนึ่งรายการในรูปแบบของ GET /api/borrows/lending
Map<String, dynamic> borrowJson({
  int id = 2,
  int assetId = 6,
  String assetName = 'Camera',
  String borrowerName = 'Somchai',
  String status = 'returned_pending',
  String paymentStatus = 'paid',
}) {
  return {
    'id': id,
    'asset_id': assetId,
    'asset_name': assetName,
    'borrower_name': borrowerName,
    'owner_name': 'sample_user',
    'planned_return_date': '2030-01-01',
    'rental_days': 1,
    'status': status,
    'payment_status': paymentStatus,
  };
}

/// ทำให้หน้าจอทดสอบสูงพอ ฟอร์มยาว ๆ จะได้ไม่ต้องเลื่อนหาปุ่ม
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// เปิดหน้าด้วยการ push ทับหน้าแรก เพื่อให้ Navigator.pop() ในหน้าทำงานได้จริง
Future<void> pumpPushed(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => screen),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
