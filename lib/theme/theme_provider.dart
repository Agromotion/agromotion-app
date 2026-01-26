import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  static const String _themeKey = "user_theme_choice";

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void setThemeMode(String themeType) async {
    if (themeType == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeType == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    notifyListeners();
    _saveTheme(themeType);
  }

  String get themeText {
    if (_themeMode == ThemeMode.light) return 'light';
    if (_themeMode == ThemeMode.dark) return 'dark';
    return 'system';
  }

  // --- Lógica de Persistência ---

  Future<void> _saveTheme(String themeType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeType);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }

      notifyListeners();
    }
  }
}
