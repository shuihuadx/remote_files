import 'dart:convert';

import 'package:html/parser.dart' as html_parser;

class CodecUtils {
  /// html文本解析
  static String htmlParse(String text) {
    if (text.isEmpty) {
      return text;
    }
    return html_parser.parse(text).body?.text ?? '';
  }

  /// 用于定义需要html转码的字符
  /// 参考: 参考: https://www.w3school.com.cn/html/html_entities.asp
  static const Map<String, String> _htmlEscapeMap = {
    '&': '&amp;',
    ' ': '&nbsp;',
    '"': '&quot;',
    "'": '&#39;',
    '<': '&lt;',
    '>': '&gt;',
    '/': '&#47;',
    '…': '&hellip;',
  };
  static const Map<String, String> _htmlEscapeMapExceptSymbolAnd = {
    ' ': '&nbsp;',
    '"': '&quot;',
    "'": '&#39;',
    '<': '&lt;',
    '>': '&gt;',
    '/': '&#47;',
    '…': '&hellip;',
  };

  /// 将_htmlEscapeMap的key和value颠倒一下, 用于解码
  static final Map<String, String> _htmlReverseEscape = _keyValueReverse(_htmlEscapeMap);
  static final Map<String, String> _htmlReverseEscapeExceptSymbolAnd =
      _keyValueReverse(_htmlEscapeMapExceptSymbolAnd);

  static Map<String, String> _keyValueReverse(Map<String, String> map) {
    Map<String, String> reverseMap = {};
    map.forEach((key, value) {
      reverseMap[value] = key;
    });
    return reverseMap;
  }

  static String onlyAndEncode(String text) {
    return htmlEncode(
      text,
      htmlEscapeMap: const {'&': '&amp;'},
    );
  }

  /// 参考: https://www.w3school.com.cn/html/html_entities.asp
  /// htmlEscape.convert() 方法是官方编码方法, 支持的字符太少
  static String htmlEncode(
    String text, {
    Map<String, String>? htmlEscapeMap,
  }) {
    if (text.isEmpty) {
      return text;
    }
    htmlEscapeMap ??= _htmlEscapeMap;
    StringBuffer sb = StringBuffer();
    int flag = 0;
    for (int i = 0; i < text.length; i++) {
      var ch = text[i];
      String? replacement = htmlEscapeMap[ch];

      if (replacement != null) {
        if (i > flag) {
          sb.write(text.substring(flag, i));
        }
        sb.write(replacement);
        flag = i + 1;
      }
    }
    if (flag < text.length) {
      sb.write(text.substring(flag, text.length));
    }
    return sb.toString();
  }

  /// 参考: https://www.w3school.com.cn/html/html_entities.asp
  /// HtmlEscape 只有编码方法, 且支持的字符太少
  /// 字符串可能会出现多次html编码的情况,例如:
  ///   "<" 经过两次编码后,会变为 "&amp;lt;"
  ///   recursion 为 true 时, 会一次性的将 "&amp;lt;" 解码为 "<"
  static String htmlDecode(
    String? text, {
    bool recursion = true,
    bool isExceptSymbolAnd = false,
  }) {
    Map<String, String> htmlReverseEscapeMap =
        isExceptSymbolAnd ? _htmlReverseEscapeExceptSymbolAnd : _htmlReverseEscape;
    return htmlDecode2(
      text,
      recursion: recursion,
      htmlReverseEscapeMap: htmlReverseEscapeMap,
    );
  }

  /// 参考: https://www.w3school.com.cn/html/html_entities.asp
  /// HtmlEscape 只有编码方法, 且支持的字符太少
  /// 字符串可能会出现多次html编码的情况,例如:
  ///   "<" 经过两次编码后,会变为 "&amp;lt;"
  ///   recursion 为 true 时, 会一次性的将 "&amp;lt;" 解码为 "<"
  static String htmlDecode2(
    String? text, {
    bool recursion = true,
    Map<String, String>? htmlReverseEscapeMap,
  }) {
    if (text == null || text.isEmpty) {
      return '';
    }
    htmlReverseEscapeMap ??= _htmlReverseEscape;

    StringBuffer sb = StringBuffer();
    bool exitsAmp = htmlReverseEscapeMap['&amp;'] != null;
    int flag = 0;
    int indexMask = 0;
    var mapKeys = htmlReverseEscapeMap.keys;
    for (int i = 0; i < text.length; i++) {
      indexMask = i;
      // 需要反转义的字符一定是以&符号开头的
      if ('&' == text[i]) {
        if (exitsAmp && text.length - i >= 5 && '&amp;' == text.substring(i, i + 5)) {
          sb.write(text.substring(flag, i));

          i += 5;
          flag = i;

          // 用于标识是否找到除&符号以外的需要反转义的字符
          bool find = false;
          // 是否需要将需要转义的文本一次转到底:
          // recursion 为 true 时, 会一次性的将 "&amp;amp;lt;" 解码为 "<"
          if (recursion) {
            // 跳过被转义多次的&符号
            while (text.length - i >= 4 && 'amp;' == text.substring(i, i + 4)) {
              i += 4;
            }
            flag = i;

            // 寻找除&符号以外的需要反转义的字符
            for (String key in mapKeys) {
              if (text.length - i >= key.length - 1 &&
                  key.substring(1) == text.substring(i, i + key.length - 1)) {
                sb.write(htmlReverseEscapeMap[key]);

                i += key.length - 1;
                flag = i;
                find = true;
                break;
              }
            }
          }
          if (!find) {
            sb.write('&');
          }
        } else {
          // 其它字符的反转义
          for (String key in mapKeys) {
            if (text.length - i >= key.length && key == text.substring(i, i + key.length)) {
              sb.write(text.substring(flag, i));
              sb.write(htmlReverseEscapeMap[key]);

              i += key.length;
              flag = i;
              break;
            }
          }
        }
      }
      // 由于for循环有i++, 为了防止i加多了, 这里需要减回去
      if (indexMask < i) {
        i--;
      }
    }
    if (flag < text.length) {
      sb.write(text.substring(flag, text.length));
    }
    return sb.toString();
  }

  static String urlEncode(String text) {
    return Uri.encodeComponent(text);
  }

  static String urlDecode(String text) {
    return Uri.decodeFull(text);
  }

  /// 字符串转换为大写
  static String upperCase(String text) {
    return text.toUpperCase();
  }

  /// 字符串转换为小写
  static String lowerCase(String text) {
    return text.toLowerCase();
  }

  static String base64Encode(String text) {
    return base64.encode(utf8.encode(text));
  }

  static String base64EncodeBytes(List<int> bytes) {
    return base64.encode(bytes);
  }

  static String base64Decode(String text) {
    return utf8.decode(base64.decode(text));
  }

  static String utf8Encode(String text) {
    return String.fromCharCodes(utf8.encode(text));
  }

  static String utf8Decode(String text) {
    return utf8.decode(text.runes.toList());
  }
}
