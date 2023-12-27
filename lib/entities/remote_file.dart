class RemoteFilesInfo {
  String title = '';
  List<RemoteFile> remoteFiles = [];

  RemoteFilesInfo({
    required this.title,
    required this.remoteFiles,
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
