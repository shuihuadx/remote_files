import 'dart:io';

import 'package:path/path.dart';
import 'package:remote_files/data/db/db_helper.dart';
import 'package:remote_files/utils/lru_cache.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  static const String tableName = 'http_disk_cache';
  static final LruCache<String, String> _memoryCache = LruCache(20);

  HttpDiskCacheImpl._();

  Future<Database> _obtainDatabase() async {
    return DBHelper.obtainDatabase();
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
    String? responseCache = _memoryCache.get(url);
    if (httpResponse == responseCache) {
      return;
    } else {
      _memoryCache.set(url, httpResponse);
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
    String? responseCache = _memoryCache.get(url);
    if (responseCache != null) {
      return responseCache;
    }
    HttpDiskCacheItem? item = await _query(rootUrl: rootUrl, url: url);
    if (item != null) {
      _memoryCache.set(url, item.httpResponse);
      return item.httpResponse;
    }
    return null;
  }

  @override
  Future<void> deleteServer(String rootUrl) {
    return _delete(rootUrl: rootUrl);
  }
}
