import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/data/db/http_disk_cache.dart';
import 'package:remote_files/data/remote_files_parser.dart';
import 'package:remote_files/entities/remote_file.dart';
import 'package:remote_files/network/network_logger.dart';

NetworkHelper networkHelper = NetworkHelper._();

class NetworkHelper {
  Dio dio = Dio();

  NetworkHelper._() {
    dio.options.connectTimeout = const Duration(seconds: 8);
    dio.options.receiveTimeout = const Duration(seconds: 8);
    dio.options.responseType = ResponseType.plain;
    dio.interceptors.add(NetworkLogger());
  }

  Future<bool> checkNetwork() async {
    Response response = await dio.get('https://bing.com');
    return response.statusCode == 200;
  }

  Future<RemoteFilesInfo?> fetchCachedRemoteFiles(String url) async {
    try {
      Configs configs = await Configs.getInstance();
      String? html = await HttpDiskCache.instance.getCache(
        rootUrl: configs.currentServerUrl,
        url: url,
      );
      if (html == null) {
        return null;
      } else {
        return RemoteFilesParser.parse(
          url: url,
          html: html,
        );
      }
    } catch (e) {
      return null;
    }
  }

  Future<RemoteFilesInfo> fetchRemoteFiles(String url) async {
    Response response = await dio.get(url);
    String html = response.data;
    Configs configs = await Configs.getInstance();
    await HttpDiskCache.instance.save(
      rootUrl: configs.currentServerUrl,
      url: url,
      httpResponse: html,
    );
    return RemoteFilesParser.parse(
      url: url,
      html: html,
    );
  }

  Future<void> downloadFile({
    required String fileUrl,
    required String localPath,
    required CancelToken cancelToken,
    ProgressCallback? onReceiveProgress,
    Function()? onDone,
    Function()? onCancel,
    Function(Exception)? onFailed,
  }) async {
    File file = File(localPath);
    // 如果文件已存在，则获取文件的大小（字节数），用于断点续传
    int downloadedBytes = file.existsSync() ? file.lengthSync() : 0;
    try {
      var response = await dio.get<ResponseBody>(
        fileUrl,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          headers: {
            /// 加入range请求头，实现断点续传
            "range": "bytes=$downloadedBytes-",
          },
        ),
      );
      File file = File(localPath);
      RandomAccessFile raf = file.openSync(mode: FileMode.append);
      int received = downloadedBytes;
      int total = await _getContentLength(response);
      Stream<Uint8List> stream = response.data!.stream;
      StreamSubscription<Uint8List>? subscription;
      subscription = stream.listen(
        (data) {
          raf.writeFromSync(data);
          received += data.length;
          onReceiveProgress?.call(received, total);
        },
        onDone: () async {
          await raf.close();
          onDone?.call();
        },
        onError: (e) async {
          await raf.close();
          onFailed?.call(e);
        },
        cancelOnError: true,
      );
      cancelToken.whenCancel.then((_) async {
        await subscription?.cancel();
        await raf.close();
      });
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        debugPrint("Download cancelled");
      } else {
        onFailed?.call(error);
      }
    }
  }

  Future<int> _getContentLength(Response<ResponseBody> response) async {
    try {
      var headerContent = response.headers.value(HttpHeaders.contentRangeHeader);
      if (headerContent != null) {
        return int.parse(headerContent.split('/').last);
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<void> uploadFile({
    required String filePath,
    required String hostServerUrl,
    required CancelToken cancelToken,
    ProgressCallback? onUploadProgress,
    Function()? onDone,
    Function()? onCancel,
    Function(Exception)? onFailed,
  }) async {
    File file = File(filePath);
    // 读取文件大小
    int uploadBytes = file.existsSync() ? file.lengthSync() : 0;
    try {
      var response = await dio.post(
        '${hostServerUrl}upload',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: path.basename(filePath)),
        }),
        cancelToken: cancelToken,
        onSendProgress: onUploadProgress,
      );
      dynamic data = json.decode(response.data);
      String? code = data['code'];
      String msg = data['msg'] ?? 'unknown error';
      if ('1' == code) {
        onDone?.call();
      } else {
        onFailed?.call(Exception(msg));
      }
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        onCancel?.call();
      } else {
        onFailed?.call(error);
      }
    } on Exception catch (error) {
      onFailed?.call(error);
    }
  }

  Future<void> deleteRemoteFile({
    required String remotePath,
    required String hostServerUrl,
  }) async {
    var response = await dio.delete(
      '$hostServerUrl$remotePath',
    );
    dynamic data = json.decode(response.data);
    String? code = data['code'];
    String msg = data['msg'] ?? 'unknown error';
    if ('1' != code) {
      throw Exception(msg);
    }
  }
}
