import 'package:flutter/material.dart';

/// todoos brand palette from splash artwork.
abstract final class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFFF06292);
  static const Color backgroundTop = Color(0xFFA9DDFB);
  static const Color background = Color(0xFFD1EFFF);
  static const Color textPrimary = Color(0xFF0D47A1);
  static const Color accent = Color(0xFFFF9800);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, background],
  );
}
