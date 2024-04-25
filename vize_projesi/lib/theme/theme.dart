import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

class ThemeManager {
  static ThemeData lightTheme = ThemeData.light();
  static ThemeData darkTheme = ThemeData.dark();

  static ThemeData getTheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTheme : lightTheme;
  }
}
