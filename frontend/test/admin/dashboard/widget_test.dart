import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/dashboard/view/dashboard_view.dart'; 


void main() {
  testWidgets('AdminDashboardScreen renders correctly and shows stats', (WidgetTester tester) async {
    // 1. จำลองการเรนเดอร์หน้า Dashboard
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminDashboardScreen(),
        ),
      ),
    );


    // 2. ตรวจสอบว่าหัวข้อหลักและข้อมูลสถิติปรากฏบนหน้าจอครบถ้วน
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Approved Items'), findsOneWidget);
    expect(find.text('1,248'), findsOneWidget);
    expect(find.text('Pending Approval'), findsOneWidget);
    expect(find.text('Currently Borrowed'), findsOneWidget);


    // 3. ตรวจสอบปุ่มรีวิวคำขอ
    expect(find.textContaining('Review'), findsOneWidget);
  });
}