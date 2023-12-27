import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 当前类用于预定义Prefs的Key值, 防止硬编码
class PrefsKeys {
  static const String remoteUrl = "app_settings";
}

/// 当前类对SharedPreferences类包装了一下, 以便以后更换库更加方便
class Prefs {
  static final Prefs _singleton = Prefs._();
  static SharedPreferences? _prefs;
  static Completer<bool>? _monitor;

  Prefs._();

  static Future<Prefs> getInstance() async {
    if (_prefs == null) {
      if (_monitor == null) {
        _monitor = Completer<bool>();
        _prefs = await SharedPreferences.getInstance();
        _monitor?.complete(true);
      } else {
        await _monitor?.future;
        _monitor = null;
      }
    }
    return _singleton;
  }

  Set<String> getKeys() {
    return _prefs?.getKeys() ?? Set();
  }

  Object? get(String key) {
    return _prefs?.get(key);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  /// 如果要设定默认返回值, 可以使用 ?? 运算符
  /// Prefs prefs = await Prefs.getInstance();
  /// String value = prefs.getString(PrefsKeys.xxx) ?? "";
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// 返回值不会为 null
  List<String> getStringList(String key) {
    return _prefs?.getStringList(key) ?? [];
  }

  bool? containsKey(String key) {
    return _prefs?.containsKey(key);
  }

  Future<bool> setString(String key, String value) async {
    bool? result = await _prefs?.setString(key, value);
    return result ?? false;
  }

  Future<bool?> setStringList(String key, List<String> value) async {
    return _prefs?.setStringList(key, value);
  }

  Future<bool> setBool(String key, bool value) async {
    if (_prefs == null) {
      return false;
    }
    return _prefs!.setBool(key, value);
  }

  Future<bool> setInt(String key, int value) async {
    if (_prefs == null) {
      return false;
    }
    return _prefs!.setInt(key, value);
  }

  Future<bool> setDouble(String key, double value) async {
    if (_prefs == null) {
      return false;
    }
    return _prefs!.setDouble(key, value);
  }

  Future<bool> remove(String key) async {
    if (_prefs == null) {
      return false;
    }
    return _prefs!.remove(key);
  }

  Future<bool> clear() async {
    if (_prefs == null) {
      return false;
    }
    return _prefs!.clear();
  }

  Future<void> reload() async {
    return _prefs?.reload();
  }

  @visibleForTesting
  static void setMockInitialValues(Map<String, Object> values) {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(values);
  }
}
