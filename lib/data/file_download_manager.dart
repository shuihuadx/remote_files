import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remote_files/app.dart';
import 'package:remote_files/data/db/file_download_record.dart';
import 'package:remote_files/network/network_helper.dart';

FileDownloadManager fileDownloadManager = FileDownloadManager._();

class FileDownloadStatus {
  Function()? onUpdate;
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

  FileDownloadStatus? get(String url) {
    return _map[url];
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
    pause(fileUrl: fileUrl);
    FileDownloadRecord fileDownloadRecord = fileDownloadStatus.fileDownloadRecord;
    // 删除文件
    File file = File(fileDownloadRecord.localPath);
    file.delete();
    // 删除数据库中的记录
    FileDownloadDB.instance.delete(fileDownloadRecord.id);
    // 移除记录
    _map.remove(fileUrl);
  }

  /// 暂停下载
  void pause({
    required String fileUrl,
  }) {
    FileDownloadStatus? fileDownloadStatus = _map[fileUrl];
    if (fileDownloadStatus == null || fileDownloadStatus.fileDownloadRecord.isDone) {
      return;
    }
    FileDownloadRecord downloadRecord = fileDownloadStatus.fileDownloadRecord;

    downloadRecord.status = DownloadStatus.pause;
    fileDownloadStatus.cancelToken?.cancel();
    fileDownloadStatus.cancelToken = null;

    FileDownloadDB.instance.updateDownload(
      id: downloadRecord.id,
      downloadBytes: downloadRecord.downloadBytes,
      fileBytes: downloadRecord.fileBytes,
      status: DownloadStatus.pause,
    );
    fileDownloadStatus.onUpdate?.call();
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
      if (fileDownloadStatus.fileDownloadRecord.isDownloading ||
          fileDownloadStatus.fileDownloadRecord.isDone) {
        // 下载中, 或者已下载完成
        return;
      }
      // 恢复下载
      await _download(fileDownloadStatus);
    }
  }

  Future<void> _download(FileDownloadStatus fileDownloadStatus) async {
    FileDownloadRecord downloadRecord = fileDownloadStatus.fileDownloadRecord;
    CancelToken cancelToken = CancelToken();
    fileDownloadStatus.cancelToken = cancelToken;
    downloadRecord.status = DownloadStatus.downloading;

    String fileUrl = downloadRecord.fileUrl;
    String localPath = downloadRecord.localPath;
    try {
      int lastTm = DateTime.now().millisecondsSinceEpoch;
      int fileBytes = -1;
      await networkHelper.downloadFile(
          fileUrl: fileUrl,
          localPath: localPath,
          cancelToken: cancelToken,
          onReceiveProgress: (int received, int total) {
            fileBytes = total;
            downloadRecord.downloadBytes = received;
            downloadRecord.fileBytes = total;
            int currentTm = DateTime.now().millisecondsSinceEpoch;
            // 避免回调过于频繁, 100ms 回调一次
            if (received == total || currentTm - lastTm > 100) {
              lastTm = currentTm;
              FileDownloadDB.instance.updateDownload(
                id: downloadRecord.id,
                downloadBytes: received,
                fileBytes: total,
                status: DownloadStatus.downloading,
              );
              fileDownloadStatus.onUpdate?.call();
            }
          },
          onDone: () {
            File file = File(localPath);
            if (file.existsSync()) {
              fileBytes = file.lengthSync();
            }

            // 下载完成
            fileDownloadStatus.cancelToken = null;
            downloadRecord.downloadBytes = fileBytes;
            fileDownloadStatus.onUpdate = null;
            downloadRecord.status = DownloadStatus.done;

            FileDownloadDB.instance.updateDownload(
              id: downloadRecord.id,
              downloadBytes: fileBytes,
              fileBytes: fileBytes,
              status: DownloadStatus.done,
            );

            fileDownloadStatus.onUpdate?.call();
          },
          onFailed: (e) {
            _onDownloadFailed(fileDownloadStatus);
          });
    } catch (e) {
      _onDownloadFailed(fileDownloadStatus);
    }
  }

  void _onDownloadFailed(FileDownloadStatus fileDownloadStatus) {
    fileDownloadStatus.cancelToken = null;
    FileDownloadRecord downloadRecord = fileDownloadStatus.fileDownloadRecord;
    downloadRecord.status = DownloadStatus.failed;

    FileDownloadDB.instance.updateDownload(
      id: downloadRecord.id,
      downloadBytes: downloadRecord.downloadBytes,
      fileBytes: downloadRecord.fileBytes,
      status: DownloadStatus.failed,
    );

    fileDownloadStatus.onUpdate?.call();
  }
}
