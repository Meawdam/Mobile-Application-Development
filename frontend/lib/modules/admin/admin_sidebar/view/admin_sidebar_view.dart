import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final String selectedMenu;
  final ValueChanged<String> onSelect;
  final Widget child;

  /// Called after the user confirms logout. When null (e.g. standalone
  /// preview) only a snackbar is shown.
  final VoidCallback? onLogout;

  const AdminSidebar({
    super.key,
    required this.selectedMenu,
    required this.onSelect,
    required this.child,
    this.onLogout,
  });

  static const Color blue = Color(0xFF1800A8);
  static const Color activeBlue = Color(0xFF1260C5);

  static const List<String> menus = [
    'Dashboard',
    'Approve Items',
    'Users & History',
    'All borrowing Records',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white,
              child: Text(
                'B',
                style: TextStyle(
                  color: blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            SizedBox(width: 10),
            Text('Borrow Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 55, 20, 25),
              color: blue,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      'B',
                      style: TextStyle(
                        color: blue,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Borrow Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Administrator',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...menus.map((menu) {
              final selected = selectedMenu == menu;

              return ListTile(
                leading: Icon(
                  _menuIcon(menu),
                  color: selected ? activeBlue : Colors.black54,
                ),
                title: Text(
                  menu,
                  style: TextStyle(
                    color: selected ? activeBlue : Colors.black87,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: selected,
                selectedTileColor: Colors.blue.shade50,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(menu);
                },
              );
            }),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: child,
    );
  }

  IconData _menuIcon(String menu) {
    switch (menu) {
      case 'Dashboard':
        return Icons.dashboard_outlined;
      case 'Approve Items':
        return Icons.fact_check_outlined;
      case 'Users & History':
        return Icons.people_outline;
      case 'All borrowing Records':
        return Icons.history;
      default:
        return Icons.circle_outlined;
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (onLogout != null) {
                onLogout!();
                return;
              }
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Logout')));
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
