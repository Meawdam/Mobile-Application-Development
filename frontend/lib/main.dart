// lib/main.dart
import 'package:flutter/material.dart';

import 'app_router.dart';

void main() {
  runApp(const BorrowApp());
}

class BorrowApp extends StatelessWidget {
  const BorrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Borrow',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      onGenerateRoute: onGenerateAppRoute,
    );
  }
}
