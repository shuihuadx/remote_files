import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:remote_files/entities/remote_file.dart';
import 'package:remote_files/network/network_logger.dart';
import 'package:remote_files/utils/codec_utils.dart';

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

  String _shortFileName(String fileName) {
    String result = fileName.replaceAll(RegExp(r'【.*?】'), '');
    return result;
  }

  Future<RemoteFilesInfo> fetchRemoteFiles(String url) async {
    Response response = await dio.get(url);

    final document = html_parser.parse(response.data);
    final anchorTags = document.getElementsByTagName('a');
    List<RemoteFile> remoteFiles = [];
    for (var anchorTag in anchorTags) {
      final String? href = anchorTag.attributes['href'];
      if (href != null && '../' != href) {
        String fileName;
        try {
          fileName = CodecUtils.urlDecode(href);
        } catch (e) {
          fileName = href;
        }
        if (fileName.endsWith('/')) {
          fileName = fileName.substring(0, fileName.length - 1);
        }
        remoteFiles.add(RemoteFile(
          fileName: _shortFileName(fileName),
          url: '$url$href',
          isDir: href.endsWith('/'),
        ));
      }
    }
    String title = url.substring(url.lastIndexOf('/', url.length - 2), url.length - 1);
    return RemoteFilesInfo(
      title: title,
      remoteFiles: remoteFiles,
    );
  }
}
