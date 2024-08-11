import 'package:remote_files/app.dart';
import 'package:remote_files/data/db/db_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FileDownloadRecord {
  int id = -1;

  /// 文件名-包含后缀
  String fileName = '';

  /// 文件远端地址
  String fileUrl = '';

  /// 文件下载的本地路径
  String localPath = '';

  /// 文件总大小
  int fileBytes = 0;

  /// 文件已下载大小
  int downloadBytes = 0;

  /// 是否下载完成
  bool complete = false;

  /// 是否处于下载中
  bool isDownloading = false;

  FileDownloadRecord();

  static FileDownloadRecord mock = FileDownloadRecord();

  FileDownloadRecord.fromDatabaseMap(Map<String, dynamic> map)
      : id = map['id'],
        fileName = map['file_name'] ?? '',
        fileUrl = map['file_url'] ?? '',
        localPath = map['local_path'] ?? '',
        fileBytes = map['file_bytes'] ?? '',
        downloadBytes = map['download_bytes'] ?? 0,
        complete = map['complete'] == 1;
}

abstract class FileDownloadDB {
  static final FileDownloadDB _emptyInstance = _EmptyFileDownloadDB();
  static final FileDownloadDB _instance = FileDownloadDBImpl._();

  static FileDownloadDB get instance {
    if (App.isAndroid || App.isIOS || App.isMacOS || App.isWindows || App.isLinux) {
      return _instance;
    } else {
      return _emptyInstance;
    }
  }

  Future<List<FileDownloadRecord>> queryAll() async {
    return [];
  }

  Future<FileDownloadRecord?> query({
    required String fileUrl,
  }) async {
    return null;
  }

  Future<FileDownloadRecord> add({
    required String fileName,
    required String fileUrl,
    required String localPath,
    required int fileBytes,
  }) async {
    return FileDownloadRecord.mock;
  }

  Future<void> updateDownload({
    required String fileUrl,
    required int downloadBytes,
    required int fileBytes,
    required bool complete,
  }) async {}

  Future<void> delete(String fileUrl) async {}
}

class _EmptyFileDownloadDB extends FileDownloadDB {}

class FileDownloadDBImpl extends FileDownloadDB {
  static const String tableName = DBHelper.tableNameFileDownloadRecord;

  FileDownloadDBImpl._();

  Future<Database> _obtainDatabase() {
    return DBHelper.obtainDatabase();
  }

  /// 当 item 冲突时, 对原数据进行替换
  Future<void> _insert({
    required String fileName,
    required String fileUrl,
    required String localPath,
    required int fileBytes,
    required int downloadBytes,
    required bool complete,
  }) async {
    final db = await _obtainDatabase();
    await db.insert(
      tableName,
      {
        'file_name': fileName,
        'file_url': fileUrl,
        'local_path': localPath,
        'file_bytes': fileBytes,
        'download_bytes': downloadBytes,
        'complete': complete ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<FileDownloadRecord?> _query({
    required String fileUrl,
  }) async {
    final db = await _obtainDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'file_url = ?',
      whereArgs: [fileUrl],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return FileDownloadRecord.fromDatabaseMap(maps.first);
  }

  Future<List<FileDownloadRecord>> _queryAll() async {
    final db = await _obtainDatabase();
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((map) => FileDownloadRecord.fromDatabaseMap(map)).toList(growable: false);
  }

  Future<void> _update({
    required String fileUrl,
    required int downloadBytes,
    required int fileBytes,
    required bool complete,
  }) async {
    final db = await _obtainDatabase();
    await db.update(
      tableName,
      {
        'download_bytes': downloadBytes,
        'file_bytes': fileBytes,
        'complete': complete ? 1 : 0,
      },
      where: 'file_url = ?',
      whereArgs: [fileUrl],
    );
  }

  Future<void> _delete({required String fileUrl}) async {
    final db = await _obtainDatabase();
    await db.delete(
      tableName,
      where: 'file_url = ?',
      whereArgs: [fileUrl],
    );
  }

  @override
  Future<List<FileDownloadRecord>> queryAll() async {
    return await _queryAll();
  }

  @override
  Future<FileDownloadRecord?> query({
    required String fileUrl,
  }) async {
    return await _query(fileUrl: fileUrl);
  }

  @override
  Future<FileDownloadRecord> add({
    required String fileName,
    required String fileUrl,
    required String localPath,
    required int fileBytes,
  }) async {
    await _insert(
      fileName: fileName,
      fileUrl: fileUrl,
      localPath: localPath,
      fileBytes: fileBytes,
      downloadBytes: 0,
      complete: false,
    );
    FileDownloadRecord? record = await _query(fileUrl: fileUrl);
    if (record == null) {
      throw Exception(
          'insert failed: fileName=$fileName,fileUrl=$fileUrl,localPath=$localPath,fileBytes=$fileBytes');
    }
    return record;
  }

  @override
  Future<void> updateDownload({
    required String fileUrl,
    required int downloadBytes,
    required int fileBytes,
    required bool complete,
  }) async {
    await _update(
      fileUrl: fileUrl,
      downloadBytes: downloadBytes,
      fileBytes: fileBytes,
      complete: complete,
    );
  }

  @override
  Future<void> delete(String fileUrl) async {
    await _delete(fileUrl: fileUrl);
  }
}
