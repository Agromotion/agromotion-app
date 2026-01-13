import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(String themeType) {
    if (themeType == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeType == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  String get themeText {
    if (_themeMode == ThemeMode.light) return 'light';
    if (_themeMode == ThemeMode.dark) return 'dark';
    return 'system';
  }
}
