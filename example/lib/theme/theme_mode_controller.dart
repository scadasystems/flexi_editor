import 'package:flutter/material.dart';

class ThemeModeController extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeModeController({ThemeMode initialThemeMode = ThemeMode.light})
    : _themeMode = initialThemeMode;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
  }

  void toggle() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
      return;
    }
    setThemeMode(ThemeMode.dark);
  }
}

