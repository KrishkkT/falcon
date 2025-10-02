import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  ThemeMode _themeMode = ThemeMode.light; // Always use light theme

  ThemeMode get themeMode => _themeMode;

  ThemeService() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      // Always use light theme
      _themeMode = ThemeMode.light;
      notifyListeners();
    } catch (e) {
      // If there's an error, default to light theme
      _themeMode = ThemeMode.light;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    // Always use light theme regardless of what's requested
    _themeMode = ThemeMode.light;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      // Always save light theme
      await prefs.setString(_themeKey, 'light');
    } catch (e) {
      // Ignore errors in saving preferences
    }
  }

  void toggleTheme() {
    // Do nothing, always keep light theme
  }
}
