import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Manages light/dark mode and remembers the user's choice
/// using the same Hive setup you already use for flashcards.
class ThemeProvider extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _themeKey = 'isDarkMode';

  ThemeMode _themeMode = ThemeMode.dark; // app currently defaults to dark
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_boxName);
    final savedIsDark = box.get(_themeKey, defaultValue: true) as bool;
    _themeMode = savedIsDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final box = await Hive.openBox(_boxName);
    await box.put(_themeKey, isDarkMode);
  }

  Future<void> setDarkMode(bool value) async {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final box = await Hive.openBox(_boxName);
    await box.put(_themeKey, value);
  }
}