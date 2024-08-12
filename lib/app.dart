import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class App {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  static BuildContext? get globalBuildContext => navigatorKey.currentContext;

  /// 参考: https://stackoverflow.com/questions/59787163/how-do-i-show-dialog-anywhere-in-the-app-without-context
  static BuildContext? get overlayContext => navigatorKey.currentState?.overlay?.context;

  static void navigatorPop() {
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState?.pop();
    }
  }

  /// 顶部状态栏的系统图标设置为浅色
  static void setLightStatusBarIcon() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: isAndroid ? Colors.transparent : Colors.grey,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  /// 顶部状态栏的系统图标设置为深色
  static void setDarkStatusBarIcon() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: isAndroid ? Colors.transparent : Colors.grey,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  /// 直接用 Platform.isWindows 的话, 在 web 端会报异常, 而是先要判断 kIsWeb, 再判断 Platform.isWindows
  static bool isWindows = !kIsWeb && Platform.isWindows;
  static bool isLinux = !kIsWeb && Platform.isLinux;
  static bool isMacOS = !kIsWeb && Platform.isMacOS;
  static bool isAndroid = !kIsWeb && Platform.isAndroid;
  static bool isIOS = !kIsWeb && Platform.isIOS;
  static bool isWeb = kIsWeb;

  static bool? _isAndroidTv;

  static FutureOr<bool> isAndroidTv() async {
    if (_isAndroidTv != null) {
      return _isAndroidTv!;
    } else {
      if (!isAndroid) {
        _isAndroidTv = false;
        return false;
      }
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      String? systemFeatures = androidInfo.systemFeatures.join(",");
      _isAndroidTv = systemFeatures.contains('android.software.leanback');

      return _isAndroidTv!;
    }
  }
}
