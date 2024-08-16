import 'package:dio/dio.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/network/network_helper.dart';

class FileUploadTask {
  List<String> filePaths = [];
  int pathIndex = 0;
  int sent = 0;
  int total = 0;
  CancelToken? cancelToken;
  Function(int index, int total)? onNextFileUpload;
  Function(int count, int total)? onUploadProgress;
  Function()? onCancel;
  Function()? onDone;
  Function(Exception)? onFailed;

  FileUploadTask._();

  static FileUploadTask build(List<String> filePaths) {
    FileUploadTask uploadTask = FileUploadTask._();
    uploadTask.filePaths = filePaths;
    return uploadTask;
  }

  void cancel() {
    cancelToken?.cancel();
  }

  Future<void> startDownload() async {
    if (filePaths.isEmpty) {
      onDone?.call();
      return;
    }
    try {
      int uploadCount = 0;
      Configs configs = Configs.getInstanceSync();
      for (int i = 0; i < filePaths.length; i++) {
        pathIndex = i;
        CancelToken cancelToken = CancelToken();
        this.cancelToken = cancelToken;
        bool uploadSuccess = false;

        onNextFileUpload?.call(i, filePaths.length);
        await networkHelper.uploadFile(
          filePath: filePaths[i],
          hostServerUrl: configs.currentServerUrl,
          cancelToken: cancelToken,
          onUploadProgress: (int sent, int total) {
            this.sent = sent;
            this.total = total;
            onUploadProgress?.call(sent, total);
          },
          onDone: () {
            uploadCount++;
          },
          onCancel: () {
            uploadSuccess = false;
            onCancel?.call();
          },
          onFailed: (e) {
            uploadSuccess = false;
            onFailed?.call(e);
          },
        );
        if (!uploadSuccess) {
          break;
        }
      }
      if (uploadCount == filePaths.length) {
        onDone?.call();
      }
    } on Exception catch (e) {
      onFailed?.call(e);
    }
  }
}
