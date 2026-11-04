
import 'package:flutter/material.dart';

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

  static const blue = Color(0xFF1800A8);
  static const activeBlue = Color(0xFF1260C5);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 275,
          color: blue,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'B',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Borrow',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.bold)),
                      Text('Admin',
                          style: TextStyle(
                              color: Colors.white, fontSize: 22)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 45),
              _menu('Dashboard'),
              _menu('Approve Items'),
              _menu('Users & History'),
              _menu('All borrowing Records'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logout')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Logout',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _menu(String title) {
    final selected = selectedMenu == title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        onTap: () => onSelect(title),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? activeBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
