import 'package:flutter/material.dart';

import 'package:frontend/utils/app_colors.dart';

/// ความกว้างของกรอบมือถือ (ต้องตรงกับ maxWidth ใน app_router.dart `_mobileWrapper`)
/// ป๊อปอัปจะถูกจำกัดให้อยู่ในกรอบนี้ ไม่ลอยเต็มหน้าจอเบราว์เซอร์
const double kMobileFrameWidth = 430;

const double _kPopupMaxWidth = 340;

/// ป๊อปอัปแจ้งผล (แทน SnackBar เดิม) แสดงกลางกรอบมือถือ
///
/// - [isSuccess] true = ไอคอนติ๊กเขียว, false = ไอคอนกากบาทแดง
/// - ต้องกดปุ่ม "OK" เพื่อปิด
/// - ข้อความ [message] จะปรากฏเพียงครั้งเดียวบนหน้าจอ (ชื่อหัวข้อเป็นคำกลาง ๆ)
Future<void> showAppPopup(
  BuildContext context, {
  required String message,
  bool isSuccess = true,
  String? title,
  String buttonLabel = 'OK',
}) {
  return showAppPopupOn(
    Navigator.of(context),
    message: message,
    isSuccess: isSuccess,
    title: title,
    buttonLabel: buttonLabel,
  );
}

/// เหมือน [showAppPopup] แต่รับ NavigatorState โดยตรง
/// ใช้ตอนที่หน้าจอปิดตัวเองไปแล้ว (pop) แต่ยังต้องโชว์ผล เช่น หลัง Add/Edit item สำเร็จ
Future<void> showAppPopupOn(
  NavigatorState navigator, {
  required String message,
  bool isSuccess = true,
  String? title,
  String buttonLabel = 'OK',
}) {
  return navigator.push<void>(
    _popupRoute<void>(
      builder: (context) => _PopupCard(
        isSuccess: isSuccess,
        title: title ?? (isSuccess ? 'Success' : 'Something went wrong'),
        message: message,
        actions: [
          _PopupButton.filled(
            label: buttonLabel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

/// ป๊อปอัปยืนยัน 2 ปุ่ม (แทน bottom sheet ยืนยันลบเดิม)
/// คืน true เมื่อกดปุ่มยืนยัน, false เมื่อกดยกเลิกหรือแตะพื้นหลัง
Future<bool> showAppConfirmPopup(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  IconData icon = Icons.delete_outline_rounded,
}) async {
  final result = await Navigator.of(context).push<bool>(
    _popupRoute<bool>(
      dismissResult: false,
      builder: (context) => _PopupCard(
        icon: icon,
        iconColor: AppColors.red,
        title: title,
        message: message,
        actions: [
          _PopupButton.filled(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          _PopupButton.text(
            label: cancelLabel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    ),
  );
  return result == true;
}

/// Route ของป๊อปอัป: scrim ถูกวาดเองภายในกรอบมือถือเท่านั้น
/// (barrier ของ route โปร่งใสและกัน tap พื้นที่ด้านข้างไว้)
Route<T> _popupRoute<T>({
  required WidgetBuilder builder,
  T? dismissResult,
}) {
  return RawDialogRoute<T>(
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: 'Popup',
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMobileFrameWidth),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // popup ยืนยัน: แตะพื้นหลัง = ยกเลิก / popup แจ้งผล: ต้องกด OK
                onTap: dismissResult == null
                    ? null
                    : () => Navigator.of(context).pop(dismissResult),
                child: const ColoredBox(color: Color(0x8A000000)),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _kPopupMaxWidth),
                    child: builder(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _PopupCard extends StatelessWidget {
  final bool isSuccess;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String message;
  final List<Widget> actions;

  const _PopupCard({
    this.isSuccess = true,
    this.icon,
    this.iconColor,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // สีเขียว/แดงใช้เฉพาะไอคอนสถานะ ปุ่มใช้สีน้ำเงินของแอปตามกติกาใน AppColors
    final color =
        iconColor ?? (isSuccess ? Colors.green.shade600 : Colors.red.shade600);
    final iconData =
        icon ?? (isSuccess ? Icons.check_rounded : Icons.close_rounded);

    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, size: 38, color: color),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.grey.shade700,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 20),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _PopupButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  const _PopupButton.filled({required this.label, required this.onPressed})
    : filled = true;

  const _PopupButton.text({required this.label, required this.onPressed})
    : filled = false;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
      child: Text(label),
    );
  }
}
