import 'package:flutter/material.dart';
import 'package:remote_files/app.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/data/db/file_download_record.dart';
import 'package:remote_files/data/file_download_manager.dart';
import 'package:remote_files/method_channel/remote_file_method_channel.dart';
import 'package:remote_files/routes/video_player_page.dart';
import 'package:remote_files/utils/file_utils.dart';
import 'package:remote_files/utils/process_helper.dart';
import 'package:remote_files/utils/snack_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class FileClickHandle {
  static Future<void> handleFileClick({
    required BuildContext context,
    required String fileName,
    required String fileUrl,
  }) async {
    Configs configs = Configs.getInstanceSync();
    bool useInnerPlayer = configs.useInnerPlayer;

    FileDownloadRecord? downloadRecord = fileDownloadManager.get(fileUrl)?.fileDownloadRecord;
    String? localPath = downloadRecord?.isDone == true ? downloadRecord?.localPath : null;

    bool isVideoFile = FileUtils.isVideoFile(fileName);

    if (isVideoFile && useInnerPlayer) {
      // 内置播放器, 仅支持 Web|Android|iOS|macOS 平台
      if (App.isAndroid || App.isIOS || App.isMacOS) {
        if (localPath == null) {
          // 使用远端地址
          Navigator.of(context).pushNamed(
            VideoPlayerPage.routeName,
            arguments: fileUrl,
          );
        } else {
          // 使用本地地址
          Navigator.of(context).pushNamed(
            VideoPlayerPage.routeName,
            arguments: localPath,
          );
        }
        return;
      }
    }

    if (App.isWindows && isVideoFile) {
      String videoPlayerPath = configs.videoPlayerPath;
      if (videoPlayerPath.isEmpty) {
        videoPlayerPath = 'C:/Program Files/Windows Media Player/wmplayer.exe';
      }
      ProcessHelper.run(
        videoPlayerPath,
        args: [fileUrl],
      );
      return;
    }

    if (App.isAndroid) {
      try {
        await RemoteFileMethodChannel.launchRemoteFile(
          fileName: fileName,
          url: fileUrl,
        );
      } catch (e) {
        SnackUtils.showSnack(
          context,
          message: isVideoFile ? '调用外部播放器失败, 请尝试使用内置播放器' : '无法打开文件, 请先在设备上安装支持打开此文件的App',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    if (!await launchUrl(Uri.parse(fileUrl))) {
      // 当前为web端时, launchUrl 会返回false, 实际上是成功的
      if (!App.isWeb) {
        SnackUtils.showSnack(
          context,
          message: '无法打开文件, 请先在设备上安装支持打开此文件的App',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }
}
