import 'package:flutter/material.dart';
//import 'package:frontend/admin/dashboard_requests_page.dart';
//import 'package:frontend/admin/approve_items_page.dart';
import 'package:frontend/modules/admin/approve_items/view/approve_items_view.dart';

class AdminDashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToApprove; // 1. เพิ่มตัวรับฟังก์ชันนี้

  const AdminDashboardScreen({
    super.key,
    this.onNavigateToApprove, // 2. รับค่าเข้ามา
  });
  //  Color Code
  static const _blue = Color(0xFF2F4BFF);
  static const _red = Color.fromARGB(255, 223, 42, 42);
  static const _yellow = Color.fromARGB(255, 252, 252, 75);
  static const _green = Color.fromARGB(255, 72, 230, 83);
  static const _onLight = Color(0xFF172554);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _onLight,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Friday, October 30, 2026',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
             
            ],
          ),
          const SizedBox(height: 20),

          // Stat Cards Grid 
          LayoutBuilder(
            builder: (context, cardConstraints) {
              int crossAxisCount = cardConstraints.maxWidth > 900
                  ? 4
                  : (cardConstraints.maxWidth > 500 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard('Approved Items', '1,248', Icons.check_circle_outline, _green),
                  _buildStatCard('Pending Approval', '3', Icons.hourglass_top_outlined, _yellow),
                  _buildStatCard('Currently Borrowed', '96', Icons.inventory_2_outlined, _blue),
                  _buildStatCard('Held Deposits', '฿84,500', Icons.account_balance_wallet_outlined, _red),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Lower Section: Chart Section
          _buildChartSection(),
        ],
      ),
    );
  }

  // Widget การ์ดสถิติพร้อมไอคอนและสีสันสดใส
  Widget _buildStatCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  color: accentColor == _yellow ? const Color(0xFFB45309) : accentColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Widget ส่วนกราฟ
  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Number of borrowing in the last 7 days',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _onLight,
                ),
              ),
              Text(
                'Times / day',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar('Mon', 35),
              _buildBar('Tue', 55),
              _buildBar('Wed', 65),
              _buildBar('Thu', 75),
              _buildBar('Fri', 95),
              _buildBar('Sat', 45),
              _buildBar('Sun', 80),
            ],
          ),
        ],
      ),
    );
  }

  // Widget แท่งกราฟ
  Widget _buildBar(String day, double height) {
    return Column(
      children: [
        Container(
          width: 16,
          height: height,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// 🔹 Widget ย่อยสำหรับปุ่ม Review Requests
class ReviewRequestsWidget extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const ReviewRequestsWidget({
    super.key,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.notifications_active_outlined, size: 16),
      label: Text(
        'Review $pendingCount requests',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2F4BFF), // ปรับให้ใช้สี _blue ของทีม
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}