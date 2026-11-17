// lib/modules/admin/admin_home.dart
// Entry point of the admin area inside the Borrow app (route: /admin).
import 'package:flutter/material.dart';

import 'approve_items/view/approve_items_view.dart';
import 'dashboard/view/dashboard_view.dart';
import 'users_history/view/users_history_view.dart';
import 'payment/view/payment_view.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // แก้ไขมาใช้ตัวแปรเก็บ index เป็นตัวเลข (เริ่มต้นที่ 0 คือ Dashboard)
  int _currentIndex = 0;

  // ฟังก์ชันสำหรับสั่งเปลี่ยนหน้าจากภายนอก (เช่น กดปุ่ม Review จาก Dashboard)
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AdminDashboardScreen(), // Index 0: Dashboard
      const ApproveItemsPage(), // Index 1: Approve (หน้าอนุมัติ)
      const UsersHistoryPage(), // Index 2: Users
      const PaymentScreen(), // Index 3: Records / Payment
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F4BFF),
        foregroundColor: Colors.white,
        title: const Text('Borrow Admin Console'),
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
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
