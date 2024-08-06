import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remote_files/app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static const String databaseName = 'remote_files.db';
  static const int databaseVersion = 1;
  static const String tableNameHttpDiskCache = 'http_disk_cache';

  static Database? _db;
  static Completer<bool>? _monitor;

  static Future<void> _createDataTables(Database db) async {
    // SQLite 中的数据类型参考: https://www.sqlite.org/datatype3.html
    // SQLite 中的 INTEGER 占 8 字节, Dart 中的 Int 也占 8 字节, 所以时间戳可以使用 INTEGER 存储
    /*
    创建 http 缓存表
    段名解释
     id: 主键(自增)
     root_url: 添加服务器时, 填入的服务器地址
     url: 实际的 url
     http_response: 上一次 http 请求体的结果
    */
    return db.execute('''CREATE TABLE $tableNameHttpDiskCache(
                id INTEGER PRIMARY KEY AUTOINCREMENT, 
                root_url TEXT, 
                url TEXT, 
                http_response TEXT)''');
  }

  static Future<Database> obtainDatabase() async {
    if (_db == null) {
      if (_monitor == null) {
        _monitor = Completer<bool>();

        _db = await _createDatabase();

        _monitor!.complete(true);
      } else {
        await _monitor!.future;
        _monitor = null;
      }
    }
    return _db!;
  }

  static Future<Database> _createDatabase() async {
    if (App.isWindows || App.isLinux) {
      databaseFactory = databaseFactoryFfi;
    }
    return openDatabase(
      join(await _getDbDirPath(), databaseName),
      version: databaseVersion,
      onCreate: (db, version) {
        debugPrint('database onCreate');
        return _createDataTables(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) {
        debugPrint('database onUpgrade');
      },
    );
  }
  static Future<String> _getDbDirPath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dirName = 'databases';
    String dirPath = join(appDocDir.path, dirName);

    if (App.isAndroid) {
      dirPath = join(appDocDir.parent.path, dirName);
    }

    if (App.isWindows || App.isLinux) {
      // Windows 和 Linux 端使用当前可执行文件的文件夹放置数据库缓存
      String executable = Platform.resolvedExecutable;
      String executableDirectory = File(executable).parent.path;
      dirPath = join(executableDirectory, 'data', dirName);
    }

    Directory result = Directory(dirPath);
    if (!result.existsSync()) {
      result.createSync(recursive: true);
    }
    return dirPath;
  }
}
