import 'package:dio/dio.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/data/db/http_disk_cache.dart';
import 'package:remote_files/data/remote_files_parser.dart';
import 'package:remote_files/entities/remote_file.dart';
import 'package:remote_files/network/network_logger.dart';

RemoteFilesFetcher remoteFilesFetcher = RemoteFilesFetcher._();

class RemoteFilesFetcher {
  Dio dio = Dio();

  RemoteFilesFetcher._() {
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
}
