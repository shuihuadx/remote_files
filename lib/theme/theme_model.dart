import 'package:flutter/material.dart';

class ThemeModel extends ChangeNotifier {
  ThemeData _themeData = ThemeData(
    primarySwatch: Colors.teal,
  );

  ThemeData get themeData => _themeData;

  void setThemeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }
}
