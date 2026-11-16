// lib/modules/admin/admin_home.dart
// Entry point of the admin area inside the Borrow app (route: /admin).
import 'package:flutter/material.dart';

import 'admin_sidebar/view/admin_sidebar_view.dart';
import 'all_transactions/view/all_transactions_view.dart';
import 'approve_items/view/approve_items_view.dart';
import 'dashboard/view/dashboard_view.dart';
import 'users_history/view/users_history_view.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String _selectedMenu = 'Dashboard';

  Widget _pageFor(String menu) {
    switch (menu) {
      case 'Approve Items':
        return const ApproveItemsPage();
      case 'Users & History':
        return const UsersHistoryPage();
      case 'All borrowing Records':
        // Kept from the previous admin UI: it has its own Scaffold/AppBar,
        // so it is shown as a pushed page instead of inside the sidebar shell.
        return const SizedBox.shrink();
      case 'Dashboard':
      default:
        return const AdminDashboardScreen();
    }
  }

  void _onSelect(String menu) {
    if (menu == 'All borrowing Records') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AllTransactionsScreen()));
      return;
    }
    setState(() => _selectedMenu = menu);
  }

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AdminSidebar(
      selectedMenu: _selectedMenu,
      onSelect: _onSelect,
      onLogout: _logout,
      child: _pageFor(_selectedMenu),
    );
  }
}
