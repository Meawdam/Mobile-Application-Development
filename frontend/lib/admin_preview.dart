
import 'package:flutter/material.dart';
import 'modules/admin/admin_module.dart';

void main() {
  runApp(const AdminPreviewApp());
}

class AdminPreviewApp extends StatefulWidget {
  const AdminPreviewApp({super.key});

  @override
  State<AdminPreviewApp> createState() => _AdminPreviewAppState();
}

class _AdminPreviewAppState extends State<AdminPreviewApp> {
  String selectedMenu = 'Approve Items';

  @override
  Widget build(BuildContext context) {
    final page = selectedMenu == 'Users & History'
        ? const UsersHistoryPage()
        : const ApproveItemsPage();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: AdminSidebar(
          selectedMenu: selectedMenu,
          onSelect: (menu) {
            if (menu == 'Approve Items' || menu == 'Users & History') {
              setState(() => selectedMenu = menu);
            }
          },
          child: page,
        ),
      ),
    );
  }
}
