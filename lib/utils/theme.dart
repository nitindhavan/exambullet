import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xff4F46E5); // Premium Indigo
  static const Color primaryLight = Color(0xffEEF2FF); // Indigo 50
  static const Color secondary = Color(0xff06B6D4); // Cyan
  
  // Backgrounds & Surface
  static const Color background = Color(0xffF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color border = Color(0xffE2E8F0); // Slate 200
  static const Color borderLight = Color(0xffF1F5F9); // Slate 100

  // Text Colors
  static const Color textPrimary = Color(0xff0F172A); // Slate 900
  static const Color textSecondary = Color(0xff64748B); // Slate 500
  static const Color textLight = Color(0xff94A3B8); // Slate 400

  // Status Colors
  static const Color success = Color(0xff10B981); // Emerald 500
  static const Color successLight = Color(0xffD1FAE5); // Emerald 100
  static const Color warning = Color(0xffF59E0B); // Amber 500
  static const Color warningLight = Color(0xffFEF3C7); // Amber 100
  static const Color error = Color(0xffEF4444); // Red 500
  static const Color errorLight = Color(0xffFEE2E2); // Red 100

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xff4F46E5), // Indigo
    Color(0xff3B82F6), // Blue
  ];

  static const List<Color> accentGradient = [
    Color(0xff3B82F6), // Blue
    Color(0xff06B6D4), // Cyan
  ];

  static const List<Color> bgGradient = [
    Color(0xffF8FAFC),
    Color(0xffF1F5F9),
  ];

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xff0F172A).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: const Color(0xff0F172A).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
