import 'package:flutter/material.dart';
import 'package:frontend/modules/admin/view/admin_sidebar_view.dart';
import 'package:frontend/modules/admin/view/approve_items_view.dart';
import 'package:frontend/modules/admin/view/dashboard_view.dart';
import 'package:frontend/modules/admin/view/users_history_view.dart';

void main() {
  runApp(const AdminPreviewApp());
}

class AdminPreviewApp extends StatefulWidget {
  const AdminPreviewApp({super.key});

  @override
  State<AdminPreviewApp> createState() => _AdminPreviewAppState();
}

class _AdminPreviewAppState extends State<AdminPreviewApp> {
  String selectedMenu = 'Dashboard';

  @override
  Widget build(BuildContext context) {
    // เลือกหน้าจอตามเมนูที่กด
    final page = selectedMenu == 'Dashboard'
        ? const AdminDashboardScreen()
        : selectedMenu == 'Users & History'
            ? const UsersHistoryPage()
            : const ApproveItemsPage();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Borrow Admin Preview',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      ),
      home: AdminSidebar(
        selectedMenu: selectedMenu,
        onSelect: (menu) {
          if (menu == 'Approve Items' || menu == 'Users & History' || menu == 'Dashboard') {
            setState(() => selectedMenu = menu);
          }
        },
        child: page,
      ),
    );
  }
}