import 'package:flutter/services.dart';
import 'package:remote_files/app.dart';
import 'package:remote_files/utils/file_utils.dart';

class RemoteFileMethodChannel {
  static const MethodChannel _channel = MethodChannel("RemoteFileMethodChannel");

  static Future<void> launchRemoteFile({
    required String fileName,
    required String url,
  }) async {
    if (App.isAndroid) {
      FileType fileType = FileUtils.getFileType(fileName);
      await _channel.invokeMethod("launchRemoteFile", {
        "fileType": fileType.name,
        "url": url,
      });
    }
  }
}
