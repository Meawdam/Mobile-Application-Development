
import 'package:flutter/material.dart';
import 'admin/admin_sidebar.dart';
import 'admin/approve_items_page.dart';
import 'admin/users_history_page.dart';
import 'admin/dashboard_page.dart';

void main() {
  runApp(const AdminPreviewApp());
}

class AdminPreviewApp extends StatefulWidget {
  const AdminPreviewApp({super.key});

  @override
  State<AdminPreviewApp> createState() => _AdminPreviewAppState();
}

class _AdminPreviewAppState extends State<AdminPreviewApp> {
  //String selectedMenu = 'Approve Items';
  String selectedMenu = 'Dashboard';

  @override
  Widget build(BuildContext context) {
   // final page = selectedMenu == 'Users & History'
      final page = selectedMenu == 'Dashboard'
        ? const AdminDashboardScreen()
        : selectedMenu == 'Users & History'
        ? const UsersHistoryPage()
        : const ApproveItemsPage();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: AdminSidebar(
          selectedMenu: selectedMenu,
          onSelect: (menu) {
            if (menu == 'Approve Items' || menu == 'Users & History'|| menu == 'Dashboard') {
              setState(() => selectedMenu = menu);
            }
          },
          child: page,
        ),
      ),
    );
  }
}
