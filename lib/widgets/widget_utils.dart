import 'package:flutter/material.dart';
import 'package:remote_files/utils/file_utils.dart';

class WidgetUtils {
  static Widget getFileIcon({
    required BuildContext context,
    required String fileName,
    required bool isDir,
  }) {
    Color themeColor = Theme.of(context).primaryColor;
    if (isDir) {
      return Icon(
        Icons.folder,
        color: themeColor,
        size: 48,
      );
    }
    switch (FileUtils.getFileType(fileName)) {
      case FileType.video:
        return Icon(
          Icons.ondemand_video,
          color: themeColor,
          size: 48,
        );
      case FileType.audio:
        return Icon(
          Icons.music_note,
          color: themeColor,
          size: 48,
        );
      case FileType.compress:
        return Icon(
          Icons.folder_zip,
          color: themeColor,
          size: 48,
        );
      case FileType.image:
        return Icon(
          Icons.image,
          color: themeColor,
          size: 48,
        );
      default:
        return Icon(
          Icons.insert_drive_file,
          color: themeColor,
          size: 48,
        );
    }
  }
}
