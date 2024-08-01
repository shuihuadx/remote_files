import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class HttpDiskCacheItem {
  int id = -1;
  String rootUrl = '';
  String url = '';
  String httpResponse = '';

  HttpDiskCacheItem.fromDatabaseMap(Map<String, dynamic> map)
      : id = map['id'],
        rootUrl = map['root_url'],
        url = map['url'],
        httpResponse = map['http_response'];
}

abstract class HttpDiskCache {
  static final HttpDiskCache _emptyInstance = _EmptyHttpDiskCache();
  static final HttpDiskCache _instance = HttpDiskCacheImpl._();

  static HttpDiskCache get instance {
    if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      return _instance;
    } else {
      return _emptyInstance;
    }
  }

  Future<void> save({
    required String rootUrl,
    required String url,
    required String httpResponse,
  }) async {}

  Future<String?> getCache({
    required String rootUrl,
    required String url,
  }) async {
    return null;
  }

  Future<void> deleteServer(String rootUrl) async {}
}

class _EmptyHttpDiskCache extends HttpDiskCache {}

class HttpDiskCacheImpl extends HttpDiskCache {
  static const String databaseName = 'remote_files.db';
  static const String tableName = 'http_disk_cache';
  static const int databaseVersion = 1;
  final Map<String, String> _memoryCache = {};
  Database? _db;

  HttpDiskCacheImpl._();

  Future<String> _getDbDirPath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dirName = 'databases';
    String dirPath = join(appDocDir.path, dirName);

    if (Platform.isAndroid) {
      dirPath = join(appDocDir.parent.path, dirName);
    }

    if (Platform.isWindows || Platform.isLinux) {
      dirPath = join(appDocDir.path, 'remote_files', 'databases');
    }

    Directory result = Directory(dirPath);
    if (!result.existsSync()) {
      result.createSync(recursive: true);
    }
    return dirPath;
  }

  Future<Database> _obtainDatabase() async {
    if (_db == null) {
      if (Platform.isWindows || Platform.isLinux) {
        databaseFactory = databaseFactoryFfi;
      } else if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      }
      _db = await openDatabase(
        join(await _getDbDirPath(), databaseName),
        version: databaseVersion,
        onCreate: (db, version) {
          debugPrint('database onCreate');
          return _createTable(db);
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) {
          debugPrint('database onUpgrade');
        },
      );
    }
    return _db!;
  }

  Future<void> _createTable(Database db) async {
    // SQLite 中的数据类型参考: https://www.sqlite.org/datatype3.html
    // SQLite 中的 INTEGER 占 8 字节, Dart 中的 Int 也占 8 字节, 所以时间戳可以使用 INTEGER 存储
    /*
    段名解释
     id: 主键(自增)
     root_url: 添加服务器时, 填入的服务器地址
     url: 实际的 url
     http_response: 上一次 http 请求体的结果
    */
    return db.execute('''CREATE TABLE $tableName(
                id INTEGER PRIMARY KEY AUTOINCREMENT, 
                root_url TEXT, 
                url TEXT, 
                http_response TEXT)''');
  }

  /// 当 item 冲突时, 对原数据进行替换
  Future<void> _insert({
    required String rootUrl,
    required String url,
    required String httpResponse,
  }) async {
    final db = await _obtainDatabase();
    await db.insert(
      tableName,
      {'root_url': rootUrl, 'url': url, 'http_response': httpResponse},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<HttpDiskCacheItem?> _query({
    required String rootUrl,
    required String url,
  }) async {
    final db = await _obtainDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'root_url = ? AND url = ?',
      whereArgs: [rootUrl, url],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return HttpDiskCacheItem.fromDatabaseMap(maps.first);
  }

  Future<void> _update({
    required String rootUrl,
    required String url,
    required String httpResponse,
  }) async {
    final db = await _obtainDatabase();

    await db.update(
      tableName,
      {'http_response': httpResponse},
      where: 'root_url = ? AND url = ?',
      whereArgs: [rootUrl, url],
    );
  }

  Future<void> _delete({required String rootUrl}) async {
    final db = await _obtainDatabase();
    await db.delete(
      tableName,
      where: 'root_url = ?',
      whereArgs: [rootUrl, url],
    );
  }

  @override
  Future<void> save({
    required String rootUrl,
    required String url,
    required String httpResponse,
  }) async {
    String? responseCache = _memoryCache[url];
    if (httpResponse == responseCache) {
      return;
    } else {
      _memoryCache[url] = httpResponse;
      HttpDiskCacheItem? item = await _query(rootUrl: rootUrl, url: url);
      if (item == null) {
        await _insert(rootUrl: rootUrl, url: url, httpResponse: httpResponse);
      } else {
        await _update(rootUrl: rootUrl, url: url, httpResponse: httpResponse);
      }
    }
  }

  @override
  Future<String?> getCache({
    required String rootUrl,
    required String url,
  }) async {
    String? responseCache = _memoryCache[url];
    if (responseCache != null) {
      return responseCache;
    }
    HttpDiskCacheItem? item = await _query(rootUrl: rootUrl, url: url);
    if (item != null) {
      _memoryCache[url] = item.httpResponse;
      return item.httpResponse;
    }
    return null;
  }

  @override
  Future<void> deleteServer(String rootUrl) async {
    List<String> keys = _memoryCache.keys.toList(growable: false);
    for (String key in keys) {
      if (key.startsWith(rootUrl)) {
        _memoryCache.remove(key);
      }
    }
    await _delete(rootUrl: rootUrl);
  }
}
