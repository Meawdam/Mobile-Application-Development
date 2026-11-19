import 'package:flutter/material.dart';

/// Shared app bar for user-facing screens.
class UserAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UserAppBar({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF172554),
      surfaceTintColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECFF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF2F4BFF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
