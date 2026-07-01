import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ── Spacing scale ─────────────────────────────────────────────────────────
  // 4pt grid. Use these instead of ad-hoc SizedBox/EdgeInsets values so
  // vertical rhythm and screen padding stay consistent everywhere.
  static const double space2 = 4;
  static const double space3 = 8;
  static const double space4 = 12;
  static const double space5 = 16;
  static const double space6 = 20;
  static const double space7 = 24;
  static const double space8 = 32;

  /// Standard horizontal page padding used by every screen body.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);

  // ── Corner radii ──────────────────────────────────────────────────────────
  static const double radiusSm = 12; // chips, small controls, inputs
  static const double radiusMd = 16; // buttons, list tiles
  static const double radiusLg = 20; // cards
  static const double radiusXl = 24; // feature cards, sheets
  static const double radiusHeader = 32; // gradient header bottom corners

  static BorderRadius get brSm => BorderRadius.circular(radiusSm);
  static BorderRadius get brMd => BorderRadius.circular(radiusMd);
  static BorderRadius get brLg => BorderRadius.circular(radiusLg);
  static BorderRadius get brXl => BorderRadius.circular(radiusXl);

  // ── Typography ────────────────────────────────────────────────────────────
  // Display / headings use Outfit; body / labels use Inter. Call these instead
  // of reaching for GoogleFonts.* or raw TextStyle() per screen.

  /// Large screen title (e.g. "My Profile", "Explore Exams").
  static TextStyle get displayLg => GoogleFonts.outfit(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      );

  /// Section / card heading.
  static TextStyle get headingMd => GoogleFonts.outfit(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      );

  /// Small heading / emphasized item title.
  static TextStyle get headingSm => GoogleFonts.outfit(
        color: textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  /// Default body text.
  static TextStyle get body => GoogleFonts.inter(
        color: textSecondary,
        fontSize: 14,
        height: 1.5,
      );

  /// Smaller supporting body text.
  static TextStyle get bodySm => GoogleFonts.inter(
        color: textSecondary,
        fontSize: 12.5,
        height: 1.45,
      );

  /// Button / strong action label.
  static TextStyle get label => GoogleFonts.inter(
        color: textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  /// Caption / hint text.
  static TextStyle get caption => GoogleFonts.inter(
        color: textLight,
        fontSize: 12,
      );

  // ── System UI overlay (status/navigation bar) ─────────────────────────────
  // The app is almost entirely light-surfaced, so the default is a transparent
  // status bar with DARK icons. Screens that place a dark/indigo surface behind
  // the status bar should wrap their body in an AnnotatedRegion with
  // [darkSurface] instead.

  /// Dark icons — use over light backgrounds (the app default).
  static const SystemUiOverlayStyle lightSurface = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android
    statusBarBrightness: Brightness.light, // iOS
    systemNavigationBarColor: surface,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  /// Light icons — use over dark/indigo backgrounds.
  static const SystemUiOverlayStyle darkSurface = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Android
    statusBarBrightness: Brightness.dark, // iOS
    systemNavigationBarColor: surface,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}
