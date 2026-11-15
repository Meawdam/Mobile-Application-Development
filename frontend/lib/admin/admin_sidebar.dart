import 'package:flutter/material.dart';

/// Shared admin shell. Navigation stays horizontal on desktop and mobile.
class AdminSidebar extends StatelessWidget {
  final String selectedMenu;
  final ValueChanged<String> onSelect;
  final Widget child;

  const AdminSidebar({
    super.key,
    required this.selectedMenu,
    required this.onSelect,
    required this.child,
  });

  static const navy = Color(0xFF111B3C);
  static const activeBlue = Color(0xFF2563EB);
  static const menus = <String>[
    'Dashboard',
    'Approve Items',
    'Users & History',
    'All borrowing Records',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return Column(
          children: [
            Container(
              color: navy,
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 24,
                compact ? 10 : 14,
                compact ? 14 : 24,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: compact ? 38 : 44,
                        height: compact ? 38 : 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'B',
                          style: TextStyle(
                            color: navy,
                            fontSize: compact ? 21 : 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Borrow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'ADMIN CONSOLE',
                              style: TextStyle(
                                color: Color(0xFFB9C6E8),
                                fontSize: 10,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logout')),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 8 : 14,
                            vertical: 9,
                          ),
                        ),
                        icon: const Icon(Icons.logout, size: 17),
                        label: Text(compact ? 'Exit' : 'Logout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: menus.map(_menuItem).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget _menuItem(String title) {
    final selected = selectedMenu == title;
    final icon = switch (title) {
      'Dashboard' => Icons.dashboard_outlined,
      'Approve Items' => Icons.inventory_2_outlined,
      'Users & History' => Icons.groups_outlined,
      _ => Icons.receipt_long_outlined,
    };

    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: InkWell(
        onTap: () => onSelect(title),
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? activeBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 7),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
