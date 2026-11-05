import 'package:flutter/material.dart';

import 'my_borrowed_items_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Borrow App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B54F6),
          surface: const Color(0xFFF5F7FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        // Keep Material touch targets usable on Android.
        visualDensity: VisualDensity.standard,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // Allow accessibility scaling, but clamp so phone layouts stay intact.
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MyBorrowedItemsPage(),
    );
  }
}
