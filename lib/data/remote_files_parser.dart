import 'package:html/parser.dart' as html_parser;
import 'package:remote_files/entities/remote_file.dart';
import 'package:remote_files/utils/codec_utils.dart';
import 'package:remote_files/utils/isolate_executor.dart';
import 'package:worker_manager/worker_manager.dart';

class RemoteFilesParser {
  static String _shortFileName(String fileName) {
    String result = fileName.replaceAll(RegExp(r'【.*?】'), '');
    return result;
  }

  static Cancelable<RemoteFilesInfo> parse({
    required String url,
    required String html,
  }) {
    return isolateExecutor.execute(parseImpl, <String, String>{
      'url': url,
      'html': html,
    });
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
