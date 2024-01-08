import 'dart:io';

import 'package:flutter/services.dart';
import 'package:remote_files/entities/remote_file.dart';
import 'package:remote_files/utils/file_utils.dart';

class RemoteFileMethodChannel {
  static const MethodChannel _channel = MethodChannel("RemoteFileMethodChannel");

  static void launchRemoteFile(RemoteFile remoteFile) {
    if (Platform.isAndroid) {
      FileType fileType = FileUtils.getFileType(remoteFile.fileName);
      _channel.invokeMethod("launchRemoteFile", {"fileType": fileType.name, "url": remoteFile.url});
    }
  }
}
