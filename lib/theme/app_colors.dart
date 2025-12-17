import 'package:flutter/material.dart';

class AppColors {
  // EXISTING (UNCHANGED)
  final Color background;
  final Color card;
  final Color text;
  final Color divider;

  // ➕ ADDED (NO BREAKING CHANGES)
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color border;

  const AppColors._({
    required this.background,
    required this.card,
    required this.text,
    required this.divider,

    // new
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.border,
  });

  factory AppColors.fromTheme(bool isDark) {
    return AppColors._(
      // EXISTING
      background: isDark ? const Color(0xFF121212) : Colors.white,
      card: isDark ? const Color(0xFF081712) : Colors.grey.shade100,
      text: isDark ? Colors.white : Colors.black87,
      divider: isDark ? Colors.grey.shade700 : Colors.grey.shade300,

      // ➕ NEW
      primaryText: isDark ? Colors.white : Colors.black87,
      secondaryText: isDark ? Colors.white70 : Colors.grey.shade600,
      accent: isDark ? Colors.greenAccent : Colors.green,
      border: isDark ? Colors.white24 : Colors.grey.shade300,
    );
  }
}
