import 'dart:io';

class ProcessHelper {
  static Future<String> run(
    String command, {
    List<String> args = const [],
  }) async {
    final result = await Process.run(command, args);
    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }
    return result.stdout;
  }
}
