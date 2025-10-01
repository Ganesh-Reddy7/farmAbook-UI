import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: Colors.white,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: const Color(0xFF081712),
  );

  static Color getAccent(BuildContext context) =>
      Theme.of(context).brightness != Brightness.dark
          ? Colors.greenAccent.shade200
          : Colors.green.shade700;

  static Color getPrimaryText(BuildContext context) =>
      Theme.of(context).brightness != Brightness.dark
          ? Colors.white
          : Colors.black87;

  static Color getSecondaryText(BuildContext context) =>
      Theme.of(context).brightness != Brightness.dark
          ? Colors.grey.shade300
          : Colors.grey.shade700;

  static Color getCardGradientStart(BuildContext context) =>
      Theme.of(context).brightness != Brightness.dark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.03);

  static Color getCardGradientEnd(BuildContext context) =>
      Theme.of(context).brightness != Brightness.dark
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.01);

  static Color getCardBorder(BuildContext context) =>
      Theme.of(context).brightness != Brightness.dark
          ? Colors.white.withOpacity(0.12)
          : Colors.black.withOpacity(0.08);
}
