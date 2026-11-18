import 'package:flutter/material.dart';

/// Central colour palette. The whole app is blue-themed.
/// Red / yellow / green are only for status indicators (never for buttons).
class AppColors {
  AppColors._();

  static const Color blue = Color(0xFF2F4BFF);
  static const Color blueLight = Color(0xFFE8EEFF);
  static const Color blueSurface = Color(0xFFF3F6FF);

  static const Color red = Color.fromARGB(255, 223, 42, 42);
  static const Color yellow = Color.fromARGB(255, 252, 252, 75);
  static const Color green = Color.fromARGB(255, 72, 230, 83);
}
