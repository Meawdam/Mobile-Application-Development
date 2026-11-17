import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/payment/view/payment_view.dart'; // ปรับ path ตามโครงสร้างโปรเจกต์ของคุณ


void main() {
  testWidgets('PaymentScreen renders correctly and handles View All tap', (WidgetTester tester) async {
    // 1. จำลองการเรนเดอร์หน้า Payment
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PaymentScreen(),
        ),
      ),
    );


    // 2. ตรวจสอบว่าข้อความหัวข้อและยอดเงินแสดงผลถูกต้อง
    expect(find.text('Payment & Refund Management'), findsOneWidget);
    expect(find.text('Collected Revenue'), findsOneWidget);
    expect(find.text('฿12,350'), findsOneWidget);


    // 3. ตรวจสอบและทดสอบการกดปุ่ม 'View All'
    expect(find.text('View All'), findsOneWidget);
    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle(); // รอให้การเปลี่ยนหน้าทำงานเสร็จสิ้น
  });
}