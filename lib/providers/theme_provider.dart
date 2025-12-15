import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeProvider() {
    _loadTheme();
  }

  /// Load saved theme from SharedPreferences
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool("isDark") ?? false;
    notifyListeners();
  }

  /// Toggle & save theme
  void toggleTheme() async {
    _isDark = !_isDark;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDark", _isDark);
    notifyListeners();
  }
}
