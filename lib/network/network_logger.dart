import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';

class NetworkLogger extends Interceptor {
  /// 拆分日志(一次性打印太多日志会被截断, 所以需要将日志拆开打印)
  void _printLongLog(String log) {
    // 一次最多打印日志长度
    int maxLogLimit = 900;
    for (int i = 0; i < log.length; i += maxLogLimit) {
      print(log.substring(i, min(i + maxLogLimit, log.length)));
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    super.onResponse(response, handler);
    bool isDebugMode = kDebugMode;
    if (isDebugMode) {
      RequestOptions requestOptions = response.requestOptions;
      // 分割线
      String url = requestOptions.uri.toString();
      String requestMethod = requestOptions.method;

      _printLongLog('$requestMethod:$url');
      if (requestMethod == 'POST' && requestOptions.data != null) {
        if (requestOptions.data is String || requestOptions.data is Map) {
          try {
            String requestBody = requestOptions.data?.toString() ?? '';
            _printLongLog('postData:$requestBody');
          } catch (e) {
            _printLongLog('postData: media type, not print');
          }
        } else {
          _printLongLog('postData: media type, not print');
        }
      }
      if (response.data != null && response.data is String) {
        String responseBody = response.data?.toString().trim() ?? '';
        _printLongLog('response:$responseBody');
      } else {
        _printLongLog('response: media type, not print');
      }
      // 分割线
      print('----------------------------------network log--------------------------------------');
    }
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    super.onError(err, handler);
  }
}
