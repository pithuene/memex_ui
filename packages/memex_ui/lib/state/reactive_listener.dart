import 'package:flutter/foundation.dart';
import 'package:memex_ui/state/state.dart';

abstract class ReactiveListener {
  /// The stack of [ReactiveListener] contexts in which execution
  /// is currently happening. Makes it possible to access the current
  /// context when accessing a [ReactiveValue].
  static final _contextStack = <ReactiveListener>[];

  @protected
  static ReactiveListener? get currentContextListener =>
      _contextStack.isEmpty ? null : _contextStack.last;

  Set<ReactiveValue> dependencies = {};

  void onDependencyChange();

  void listenTo(ReactiveValue dependency) {
    if (dependencies.add(dependency)) {
      dependency.addListener(onDependencyChange);
    }
  }

  void removeAllListeners() {
    for (var dependency in dependencies) {
      dependency.removeListener(onDependencyChange);
    }
    dependencies.clear();
  }

  void executeInContext(Function() exec) {
    _contextStack.add(this);
    exec();
    assert(_contextStack.last == this);
    _contextStack.removeLast();
  }
}
