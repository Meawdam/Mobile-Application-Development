// lib/modules/admin/admin_home.dart
// Entry point of the admin area inside the Borrow app (route: /admin).
import 'package:flutter/material.dart';

import 'approve_items/view/approve_items_view.dart';
import 'dashboard/view/dashboard_view.dart';
import 'users_history/view/users_history_view.dart';
import 'payment/view/payment_view.dart';
import 'package:frontend/services/auth_service.dart';
import '../auth/login/view/login_view.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // แก้ไขมาใช้ตัวแปรเก็บ index เป็นตัวเลข (เริ่มต้นที่ 0 คือ Dashboard)
  int _currentIndex = 0;
  final Authservice _authService = Authservice();

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access admin tools.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _authService.deleteToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ฟังก์ชันสำหรับสั่งเปลี่ยนหน้าจากภายนอก (เช่น กดปุ่ม Review จาก Dashboard)
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const tabTitles = ['Dashboard', 'Approve items', 'Users & history', 'Records'];
    final pages = [
      AdminDashboardScreen(
        onNavigateToApprove: () => changeTab(1),
        onNavigateToRecords: () => changeTab(3),
      ),
      const ApproveItemsPage(), // Index 1: Approve (หน้าอนุมัติ)
      const UsersHistoryPage(), // Index 2: Users
      const PaymentScreen(), // Index 3: Records / Payment
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172554),
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF2F4BFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Borrow Admin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  Text(tabTitles[_currentIndex], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton.filledTonal(
              tooltip: 'Log out',
              onPressed: _logout,
              style: IconButton.styleFrom(foregroundColor: const Color(0xFFB54747), backgroundColor: const Color(0xFFFFEEEE)),
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: const Color(0xFFE8ECFF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Approve',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Records',
          ),
        ],
      ),
    );
  }
}
