class RemoteFilesInfo {
  String title = '';
  List<RemoteFile> remoteFiles = [];
  String htmlResponse = '';

  RemoteFilesInfo({
    required this.title,
    required this.remoteFiles,
    required this.htmlResponse,
  });
}

class RemoteFile {
  String fileName = '';
  String url = '';
  bool isDir = false;

  RemoteFile({
    required this.fileName,
    required this.url,
    required this.isDir,
  });
}
