import 'package:flutter/foundation.dart';
import './reactive_listener.dart';

abstract class ReactiveValue<T> implements Listenable, ValueListenable<T> {}

class Prop<T> extends ChangeNotifier implements ReactiveValue<T> {
  T _value;
  Prop(this._value);

  // TODO: Call shorthand for getting the value?
  // T call() => value;

  @override
  T get value {
    ReactiveListener.currentContextListener?.listenTo(this);
    return _value;
  }

  set value(T val) {
    _value = val;
    notifyListeners();
  }
}

/// A [ReactiveValue] which isn't actually mutable.
/// Useful when setting properties which expect a [ReactiveValue]
/// to a constant value.
class Const<T> implements ReactiveValue<T> {
  final T _value;

  const Const(this._value);

  @override
  T get value => _value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
