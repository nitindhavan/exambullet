import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Per-category visual theme: a bundled banner illustration + an accent colour.
///
/// Images live at `assets/categories/{categoryId}.png` (bundled). Colours are
/// baked in here. Everything degrades gracefully: a category with no bundled
/// image just shows the accent-tinted fallback, so the UI never breaks before
/// the art is added.
class CategoryTheme {
  const CategoryTheme(this.accent);
  final Color accent;

  /// Asset path for a category's banner, by convention.
  static String assetFor(String categoryId) =>
      'assets/categories/$categoryId.png';

  /// Baked-in accent colour per category id (see the exam-theme table). Unknown
  /// categories fall back to the app's indigo.
  static Color accentFor(String categoryId) {
    return _accents[categoryId] ?? const Color(0xff4F46E5);
  }

  static const Color _fallback = Color(0xff4F46E5);

  static const Map<String, Color> _accents = {
    'railways': Color(0xff1E40AF), // deep blue
    'banking-insurance': Color(0xff059669), // emerald
    'ssc': Color(0xff4F46E5), // indigo
    'defence-police': Color(0xff475569), // steel
    'teaching': Color(0xffD97706), // amber
    'state-psc': Color(0xff0D9488), // teal
    'engineering-psu': Color(0xff3730A3), // slate blue
    'medical-nursing': Color(0xffE11D48), // rose
    'agriculture': Color(0xff16A34A), // green
    'clerical-admin': Color(0xff0891B2), // cyan
    'taxation-finance': Color(0xff7C3AED), // violet
    'scholarship-entrance': Color(0xffCA8A04), // gold
    'other': Color(0xff64748B), // gray
  };

  /// Cache of which category assets actually exist in the bundle, so cards can
  /// choose the illustration vs the fallback without a per-frame async check.
  static final Map<String, bool> _assetExists = {};

  /// Returns true if a bundled banner image exists for [categoryId]. Cached.
  static Future<bool> hasImage(String categoryId) async {
    final cached = _assetExists[categoryId];
    if (cached != null) return cached;
    try {
      await rootBundle.load(assetFor(categoryId));
      _assetExists[categoryId] = true;
      return true;
    } catch (_) {
      _assetExists[categoryId] = false;
      return false;
    }
  }

  /// Synchronous best-effort read of the existence cache (null = unknown yet).
  static bool? cachedHasImage(String categoryId) => _assetExists[categoryId];

  static Color get fallbackAccent => _fallback;
}
