import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_files/app.dart';
import 'package:remote_files/theme/theme_model.dart';

class AppTheme {
  static ThemeModel themeModel = ThemeModel();
  static SystemUiOverlayStyle systemOverlayStyle = SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }

  static ThemeData createThemeDataByColor(Color color) {
    if (App.isAndroidTvSync() ?? false) {
      return _createThemeDataByColorDark(color);
    } else {
      return _createThemeDataByColorLight(color);
    }
  }

  static ThemeData _createThemeDataByColorLight(Color color) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: Brightness.light,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: color,
      ),
      dialogTheme: DialogThemeData(
        // actionsPadding: EdgeInsets.all(0),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Color(0xff333333), fontSize: 18),
        bodyLarge: TextStyle(color: Color(0xff333333), fontSize: 18),
        bodyMedium: TextStyle(color: Color(0xff333333), fontSize: 16),
        bodySmall: TextStyle(color: Color(0xff999999), fontSize: 12),
        labelMedium: TextStyle(color: Color(0xffbbbbbb), fontSize: 16),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.grey,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        suffixIconColor: Colors.grey,
      ),
      dividerColor: const Color(0xffe5e5e5),
      primarySwatch: createMaterialColor(color),
      scaffoldBackgroundColor: Colors.white,
    );
  }

  static ThemeData _createThemeDataByColorDark(Color color) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: Brightness.light,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: color,
      ),
      dialogTheme: DialogThemeData(
        // actionsPadding: EdgeInsets.all(0),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xff1a1a1a),
      ),
      primarySwatch: createMaterialColor(color),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Color(0xffcccccc), fontSize: 18),
        bodyLarge: TextStyle(color: Color(0xffcccccc), fontSize: 18),
        bodyMedium: TextStyle(color: Color(0xffcccccc), fontSize: 16),
        bodySmall: TextStyle(color: Color(0xff666666), fontSize: 12),
        labelMedium: TextStyle(color: Color(0xff444444), fontSize: 16),
      ),
      scaffoldBackgroundColor: Colors.grey[800],
    );
  }
}
