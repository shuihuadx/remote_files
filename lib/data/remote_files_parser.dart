import 'dart:async';

import 'package:html/parser.dart' as html_parser;
import 'package:remote_files/entities/remote_file.dart';
import 'package:remote_files/utils/codec_utils.dart';
import 'package:remote_files/utils/isolate_executor.dart';
import 'package:remote_files/utils/lru_cache.dart';

class RemoteFilesParser {
  /// 缓存解析结果, 方便复用(key:url, value:RemoteFilesInfo)
  static final LruCache<String, RemoteFilesInfo> _parseCache = LruCache(20);

  static String _shortFileName(String fileName) {
    String result = fileName.replaceAll(RegExp(r'【.*?】'), '');
    return result;
  }

  static FutureOr<RemoteFilesInfo> parse({
    required String url,
    required String html,
  }) async {
    // 尝试使用缓存
    RemoteFilesInfo? cache = _parseCache.get(url);
    if (cache != null && html == cache.htmlResponse) {
      return cache;
    } else {
      RemoteFilesInfo remoteFilesInfo = await isolateExecutor.execute(
        parseImpl,
        <String, String>{
          'url': url,
          'html': html,
        },
      );
      _parseCache.set(url, remoteFilesInfo);
      return remoteFilesInfo;
    }
  }

  static RemoteFilesInfo parseImpl(Map<String, String> arg) {
    String url = arg['url']!;
    String html = arg['html']!;
    final document = html_parser.parse(html);
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
      htmlResponse: html,
    );
  }
}
