import 'package:flutter/material.dart';
import 'package:remote_files/theme/app_theme.dart';

class ThemeModel extends ChangeNotifier {
  ThemeData _themeData = AppTheme.createThemeDataByColor(Colors.teal);

  ThemeData get themeData => _themeData;

  void setThemeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }
}
