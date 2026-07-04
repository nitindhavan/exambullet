import 'package:flutter/material.dart';

/// Maps a category's stored `icon` key (a short string in the `categories` node)
/// to a Flutter [IconData]. Keeping the DB value a stable string keeps the data
/// portable; both the user app and admin resolve it through this same table.
///
/// The keys here are the canonical set an admin can choose from.
const Map<String, IconData> kCategoryIcons = {
  'account_balance': Icons.account_balance_rounded,
  'account_balance_wallet': Icons.account_balance_wallet_rounded,
  'description': Icons.description_rounded,
  'train': Icons.train_rounded,
  'school': Icons.school_rounded,
  'shield': Icons.shield_rounded,
  'engineering': Icons.engineering_rounded,
  'local_hospital': Icons.local_hospital_rounded,
  'agriculture': Icons.agriculture_rounded,
  'badge': Icons.badge_rounded,
  'receipt_long': Icons.receipt_long_rounded,
  'workspace_premium': Icons.workspace_premium_rounded,
  'category': Icons.category_rounded,
  'gavel': Icons.gavel_rounded,
  'science': Icons.science_rounded,
  'computer': Icons.computer_rounded,
  'directions_bus': Icons.directions_bus_rounded,
  'flight': Icons.flight_rounded,
  'water_drop': Icons.water_drop_rounded,
  'bolt': Icons.bolt_rounded,
  'menu_book': Icons.menu_book_rounded,
  'health_and_safety': Icons.health_and_safety_rounded,
};

/// Resolves a category icon key to an [IconData], defaulting to a generic
/// category icon when the key is empty or unknown.
IconData categoryIconFor(String? key) =>
    kCategoryIcons[key] ?? Icons.category_rounded;
