import 'dart:async';

import 'package:worker_manager/worker_manager.dart';

IsolateExecutor isolateExecutor = IsolateExecutor();

typedef Fun<A, O> = FutureOr<O> Function(A arg);

class IsolateExecutor {
  bool _isInit = false;
  Completer<bool>? _monitor;

  FutureOr<void> init() async {
    if (!_isInit) {
      if (_monitor == null) {
        _monitor = Completer<bool>();
        await workerManager.init(isolatesCount: 1);
        _monitor!.complete(true);
      } else {
        await _monitor!.future;
        _monitor = null;
      }
      _isInit = true;
    }
  }

  Cancelable<O> execute<A, O>(Fun<A, O> fun, A arg) {
    return workerManager.execute<O>(
      () async {
        return fun(arg);
      },
      priority: WorkPriority.immediately,
    );
  }
}
