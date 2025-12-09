import 'package:flutter/material.dart';

class AppColors {
  final Color background;
  final Color card;
  final Color text;
  final Color divider;

  const AppColors._({
    required this.background,
    required this.card,
    required this.text,
    required this.divider,
  });

  /// Create theme colors based on dark/light mode
  factory AppColors.fromTheme(bool isDark) {
    return AppColors._(
      background: isDark ? const Color(0xFF121212) : Colors.white,
      card: isDark ? const Color(0xFF081712) : Colors.grey.shade100,
      text: isDark ? Colors.white : Colors.black87,
      divider: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
    );
  }
}
