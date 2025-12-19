import 'package:flutter/material.dart';

class AppColors {
  final Color background;
  final Color card;
  final Color text;
  final Color divider;

  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color border;
  final Color cardGradientStart;
  final Color cardGradientEnd;

  const AppColors._({
    required this.background,
    required this.card,
    required this.text,
    required this.divider,

    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.border,
    required this.cardGradientStart,
    required this.cardGradientEnd
  });

  factory AppColors.fromTheme(bool isDark) {
    return AppColors._(
      background: isDark ? const Color(0xFF121212) : Colors.white,
      card: isDark ? const Color(0xFF081712) : Colors.grey.shade100,
      text: isDark ? Colors.white : Colors.black87,
      divider: isDark ? Colors.grey.shade700 : Colors.grey.shade300,

      primaryText: isDark ? Colors.white : Colors.black87,
      secondaryText: isDark ? Colors.white70 : Colors.grey.shade600,
      accent: isDark ? Colors.greenAccent : Colors.green,
      border: isDark ? Colors.white24 : Colors.grey.shade300,
      cardGradientStart: Colors.transparent,
      cardGradientEnd: Colors.transparent,
    );
  }
}
