import 'package:flutter/material.dart';
import 'package:frontend/utils/app_colors.dart';

class ReviewRequestsWidget extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const ReviewRequestsWidget({
    super.key,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.notifications_active_outlined, size: 16),
      label: Text(
        'Review $pendingCount requests',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}
