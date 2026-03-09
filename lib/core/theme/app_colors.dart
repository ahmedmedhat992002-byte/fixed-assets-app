import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1E3BEA);
  static const Color primaryDark = Color(0xFF1025A4);
  static const Color primaryLight = Color(0xFFE3E7FF);
  static const Color primarySoft = Color(0xFFF0F2FF); // Modern soft primary
  static const Color black = Color(0xFF000000);

  // Transparent / Glass variants
  static Color glassWhite = Colors.white.withValues(alpha: 0.7);
  static Color glassBackground = const Color(0xFFF5F7FB).withValues(alpha: 0.82);

  static const Color secondary = Color(0xFFFFC400);
  static const Color success = Color(0xFF1BA462);
  static const Color warning = Color(0xFFFF8A00);
  static const Color danger = Color(0xFFFF4D4F);

  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF2F4F7);
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textMuted = Color(0xFF98A2B3);

  static const Color divider = Color(0xFFE4E7EC);
  static const Color border = Color(0xFFCBD5F5);
}
