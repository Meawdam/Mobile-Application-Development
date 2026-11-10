import 'package:frontend/modules/admin/medels/dashboard_model.dart';

class DashboardController {
  // ดึงข้อมูลสถิติจากหลังบ้าน
  Future<DashboardStats> fetchDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock Data สอดคล้องกับหน้าจอหลัก
    return DashboardStats(
      approvedCount: 1248,
      pendingCount: 8,
      borrowedCount: 96,
    );
  }

  // ตรวจสอบว่ายังมีคำขอที่รออนุมัติอยู่หรือไม่
  bool hasPendingRequests(int pendingCount) {
    return pendingCount > 0;
  }
}