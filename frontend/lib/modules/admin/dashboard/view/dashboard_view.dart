import 'package:flutter/material.dart';

import '../controller/dashboard_controller.dart';
import '../model/dashboard_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToApprove; // 1. เพิ่มตัวรับฟังก์ชันนี้

  const AdminDashboardScreen({
    super.key,
    this.onNavigateToApprove, // 2. รับค่าเข้ามา
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  //  Color Code
  static const _blue = Color(0xFF2F4BFF);
  static const _red = Color.fromARGB(255, 223, 42, 42);
  static const _yellow = Color.fromARGB(255, 252, 252, 75);
  static const _green = Color.fromARGB(255, 72, 230, 83);
  static const _onLight = Color(0xFF172554);

  final DashboardController _controller = DashboardController();
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _controller.fetchDashboardStats();
  }

  void _reload() {
    setState(() {
      _statsFuture = _controller.fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _onLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _todayLabel(),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _reload,
                    tooltip: 'Refresh dashboard',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          snapshot.error.toString().replaceFirst(
                            'Exception: ',
                            '',
                          ),
                          style: const TextStyle(color: _red),
                        ),
                      ),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, cardConstraints) {
                  final crossAxisCount = cardConstraints.maxWidth > 900
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
                      _buildStatCard(
                        'Approved Items',
                        stats?.approvedCount.toString() ?? '--',
                        Icons.check_circle_outline,
                        _green,
                      ),
                      _buildStatCard(
                        'Pending Approval',
                        stats?.pendingCount.toString() ?? '--',
                        Icons.hourglass_top_outlined,
                        _yellow,
                      ),
                      _buildStatCard(
                        'Currently Borrowed',
                        stats?.borrowedCount.toString() ?? '--',
                        Icons.inventory_2_outlined,
                        _blue,
                      ),
                      _buildStatCard(
                        'Held Deposits',
                        stats == null
                            ? '--'
                            : _formatCurrency(stats.heldDeposits),
                        Icons.account_balance_wallet_outlined,
                        _red,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildChartSection(stats),
            ],
          ),
        );
      },
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '฿$whole.${parts.last}';
  }

  // Widget การ์ดสถิติพร้อมไอคอนและสีสันสดใส
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
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
                  color: accentColor == _yellow
                      ? const Color(0xFFB45309)
                      : accentColor,
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
  Widget _buildChartSection(DashboardStats? stats) {
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
          if (stats == null || stats.borrowingVolume.isEmpty)
            const Text(
              'No borrowing activity in the last 7 days.',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            )
          else
            _buildBorrowingChart(stats.borrowingVolume),
        ],
      ),
    );
  }

  // Widget แท่งกราฟ
  Widget _buildBorrowingChart(List<DailyBorrowingStats> borrowingVolume) {
    final maximum = borrowingVolume.fold<int>(
      0,
      (value, day) => day.count > value ? day.count : value,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: borrowingVolume.map((day) {
        final date = DateTime.tryParse(day.date);
        final label = date == null
            ? day.date
            : const [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ][date.weekday - 1];
        final height = maximum == 0 ? 0.0 : 95 * day.count / maximum;
        return Column(
          children: [
            Text(
              day.count.toString(),
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 4),
            _buildBar(label, height),
          ],
        );
      }).toList(),
    );
  }

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
