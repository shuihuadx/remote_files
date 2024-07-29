import 'dart:async';

import 'package:dlna_dart/dlna.dart';

class DlnaUtils {
  static bool _isStop = false;
  static bool _isSearching = false;
  static DLNAManager _searcher = DLNAManager();
  static Map<String, DLNADevice> _deviceList = {};

  static Map<String, DLNADevice> get deviceList => _deviceList;

  static Function()? deviceListUpdateListener;

  static Future<void> startSearch() async {
    if (_isSearching) {
      return;
    }
    if (_isStop) {
      _searcher = DLNAManager();
    }
    _isSearching = true;
    DeviceManager m = await _searcher.start();
    m.devices.stream.listen((deviceList) {
      _deviceList = deviceList;
      deviceListUpdateListener?.call();
    });
  }

  static void stop() {
    _searcher.stop();
    _isStop = true;
    _isSearching = false;
    if (_deviceList.isNotEmpty) {
      _deviceList.clear();
      deviceListUpdateListener?.call();
    }
  }

  static Future<void> play(DLNADevice device, String url) async {
    await device.setUrl(url);
    await device.play();
  }
}
