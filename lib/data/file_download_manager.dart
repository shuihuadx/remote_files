import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remote_files/app.dart';
import 'package:remote_files/data/db/file_download_record.dart';
import 'package:remote_files/network/remote_files_fetcher.dart';

FileDownloadManager fileDownloadManager = FileDownloadManager._();

typedef ProgressCallback = void Function(int downloadBytes, int totalBytes);

class FileDownloadStatus {
  /// 是否处于下载中
  bool isDownloading = false;

  ProgressCallback? progressCallback;
  CancelToken? cancelToken;
  FileDownloadRecord fileDownloadRecord;

  FileDownloadStatus({
    required this.fileDownloadRecord,
  });
}

class FileDownloadManager {
  FileDownloadManager._();

  final LinkedHashMap<String, FileDownloadStatus> _map = LinkedHashMap();

  Future<void> init() async {
    List<FileDownloadRecord> list = await FileDownloadDB.instance.queryAll();
    for (var item in list) {
      _map[item.fileUrl] = FileDownloadStatus(fileDownloadRecord: item);
    }
  }

  List<FileDownloadStatus> getAll() {
    return _map.values.toList();
  }

  static Future<String> _getDownloadPath(String fileName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dirName = 'download';
    String dirPath = join(appDocDir.path, dirName);

    if (App.isAndroid) {
      Directory androidDir = await getExternalStorageDirectory() ?? appDocDir;
      dirPath = join(androidDir.path, dirName);
    }

    if (App.isWindows || App.isLinux) {
      // Windows 和 Linux 端使用当前可执行文件的文件夹放置文件下载位置
      String executable = Platform.resolvedExecutable;
      String executableDirectory = File(executable).parent.path;
      dirPath = join(executableDirectory, 'data', dirName);
    }

    Directory result = Directory(dirPath);
    if (!await result.exists()) {
      await result.create(recursive: true);
    }
    File file = File('$dirPath/$fileName');
    int flag = 0;
    while (await file.exists()) {
      flag++;
      file = File('$dirPath/$fileName-$flag');
    }
    return file.path;
  }

  /// 删除下载记录, 并删除文件
  void delete({
    required String fileUrl,
  }) {
    FileDownloadStatus? fileDownloadStatus = _map[fileUrl];
    if (fileDownloadStatus == null) {
      return;
    }
    // 先取消下载
    cancel(fileUrl: fileUrl);
    FileDownloadRecord fileDownloadRecord = fileDownloadStatus.fileDownloadRecord;
    // 删除数据库中的记录
    FileDownloadDB.instance.delete(fileUrl);
    // 删除文件
    File file = File(fileDownloadRecord.localPath);
    file.delete();
    // 移除记录
    _map.remove(fileUrl);
  }

  /// 取消下载
  void cancel({
    required String fileUrl,
  }) {
    FileDownloadStatus? fileDownloadStatus = _map[fileUrl];
    if (fileDownloadStatus == null || fileDownloadStatus.fileDownloadRecord.complete) {
      return;
    }
    fileDownloadStatus.isDownloading = false;
    fileDownloadStatus.cancelToken?.cancel();
    fileDownloadStatus.cancelToken = null;
  }

  /// 开始下载或恢复下载
  void startDownload({
    required String fileName,
    required String fileUrl,
  }) async {
    FileDownloadStatus? fileDownloadStatus = _map[fileUrl];
    if (fileDownloadStatus == null) {
      // 下载记录不存在, 新建下载
      String localPath = await _getDownloadPath(fileName);
      FileDownloadRecord fileDownloadRecord = await FileDownloadDB.instance.add(
        fileName: fileName,
        fileUrl: fileUrl,
        localPath: localPath,
        fileBytes: -1,
      );
      fileDownloadStatus = FileDownloadStatus(fileDownloadRecord: fileDownloadRecord);
      _map[fileUrl] = fileDownloadStatus;

      await _download(fileDownloadStatus);
    } else {
      // 下载记录已存在
      if (fileDownloadStatus.isDownloading || fileDownloadStatus.fileDownloadRecord.complete) {
        // 下载中, 或者已下载完成
        return;
      }
      // 恢复下载
      await _download(fileDownloadStatus);
    }
  }

  Future<void> _download(FileDownloadStatus fileDownloadStatus) async {
    CancelToken cancelToken = CancelToken();
    fileDownloadStatus.cancelToken = cancelToken;
    fileDownloadStatus.isDownloading = true;

    String fileUrl = fileDownloadStatus.fileDownloadRecord.fileUrl;
    String localPath = fileDownloadStatus.fileDownloadRecord.localPath;
    try {
      int lastReceived = 0;
      int fileBytes = -1;
      await remoteFilesFetcher.downloadFile(
        fileUrl: fileUrl,
        localPath: localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (int received, int total) {
          fileBytes = total;
          fileDownloadStatus.fileDownloadRecord.downloadBytes = received;
          fileDownloadStatus.fileDownloadRecord.fileBytes = total;
          fileDownloadStatus.progressCallback?.call(received, total);
          // 防止数据库更新太过频繁, 这里做一下限制
          int diff = received - lastReceived;
          if (received == total || (diff > 1024 * 1024 && diff > total / 100)) {
            lastReceived = received;
            FileDownloadDB.instance.updateDownload(
              fileUrl: fileUrl,
              downloadBytes: received,
              fileBytes: total,
              complete: false,
            );
          }
        },
      );
      File file = File(localPath);
      if (file.existsSync()) {
        fileBytes = file.lengthSync();
      }

      // 下载完成
      fileDownloadStatus.isDownloading = false;
      fileDownloadStatus.cancelToken = null;
      fileDownloadStatus.fileDownloadRecord.downloadBytes = fileBytes;
      fileDownloadStatus.progressCallback?.call(fileBytes, fileBytes);
      fileDownloadStatus.progressCallback = null;

      fileDownloadStatus.fileDownloadRecord.complete = true;
      fileDownloadStatus.fileDownloadRecord.complete = true;

      FileDownloadDB.instance.updateDownload(
        fileUrl: fileUrl,
        downloadBytes: fileBytes,
        fileBytes: fileBytes,
        complete: true,
      );
    } catch (e) {
      // 网络错误, 或者下载被取消
    }
  }
}
