import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:remote_files/utils/prefs.dart';

class Configs {
  static const String _prefsKeyRemoteServers = "remote_servers";
  int themeColor = Colors.teal.value;
  List<RemoteServer> remoteServers = [];
  String currentServerUrl = "";
  /// 三方视频播放器的地址
  String videoPlayerPath = "";

  static Configs? _singleton;
  static Completer<bool>? _monitor;

  static Future<Configs> getInstance() async {
    if (_singleton == null) {
      // 由于AppSettings._getAppSettings()方法是一个耗时的方法
      // 当同时有多个地方调用getInstance()时, 可能会创建多个AppSettings对象出来
      // 所以这里创建一个监视器,当发现AppSettings对象正在创建过程中时,就等待执行完成
      // 补充说明: 同一个future可以被多次await
      if (_monitor == null) {
        _monitor = Completer<bool>();
        _singleton = await Configs._getConfigs();
        _monitor!.complete(true);
      } else {
        await _monitor!.future;
        _monitor = null;
      }
    }

    return _singleton!;
  }

  // 必须是先执行过 getInstance保证获取到的设置不为null
  static Configs getInstanceSync() {
    if (_singleton == null) {
      throw ArgumentError('Configs没有提前初始化');
    }
    return _singleton!;
  }

  /// private 获取本地存储的AppSettings
  /// 如果本地没有, 则返回 一个默认的AppSettings
  static Future<Configs> _getConfigs() async {
    Prefs prefs = await Prefs.getInstance();
    String? appSettingsJson = prefs.getString(_prefsKeyRemoteServers);

    appSettingsJson ??= '{}';

    Map<String, dynamic> map = await json.decode(appSettingsJson);
    return Configs._fromPersistenceMap(map);
  }

  /// private 从持久化读取出来的 map 转换为 AppSettings 对象
  Configs._fromPersistenceMap(Map<String, dynamic> map) {
    themeColor = map['themeColor'] ?? themeColor;
    currentServerUrl = map['currentServerUrl'] ?? "";
    videoPlayerPath = map['videoPlayerPath'] ?? "";
    (map['remoteServers'] ?? []).forEach((e) {
      RemoteServer remoteServer = RemoteServer();
      remoteServer.serverName = e['serverName'] ?? '';
      remoteServer.serverUrl = e['serverUrl'] ?? '';
      remoteServers.add(remoteServer);
    });
  }

  /// private 转化为将要持久化的 map
  Map<String, dynamic> _toPersistenceMap() {
    return <String, dynamic>{
      'themeColor': themeColor,
      'remoteServers': remoteServers
          .map((e) => {
                'serverName': e.serverName ?? '',
                'serverUrl': e.serverUrl,
              })
          .toList(growable: false),
      'currentServerUrl': currentServerUrl,
      'videoPlayerPath': videoPlayerPath,
    };
  }

  /// 保存AppSettings
  Future<bool> save() async {
    String jsonString = json.encode(_toPersistenceMap());
    Prefs prefs = await Prefs.getInstance();
    return prefs.setString(_prefsKeyRemoteServers, jsonString);
  }
}

class RemoteServer {
  String serverName = "";
  String serverUrl = "";
}
