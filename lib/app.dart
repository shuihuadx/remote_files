import 'dart:io';

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
      statusBarColor: Platform.isAndroid ? Colors.transparent : Colors.grey,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  /// 顶部状态栏的系统图标设置为深色
  static void setDarkStatusBarIcon() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Platform.isAndroid ? Colors.transparent : Colors.grey,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }
}
