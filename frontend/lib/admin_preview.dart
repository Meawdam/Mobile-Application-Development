import 'package:flutter/material.dart';
import 'admin/approve_items_page.dart';
import 'admin/users_history_page.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminShell(),
    ));

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    const pages = [
      Center(child: Text('Dashboard (teammate)')),
      ApproveItemsPage(),
      UsersHistoryPage(),
      Center(child: Text('Records (teammate)')),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F4BFF),
        foregroundColor: Colors.white,
        title: const Text('Borrow Admin'),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Approve'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Records'),
        ],
      ),
    );
  }
}