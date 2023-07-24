import 'package:flutter/foundation.dart';
import 'package:memex_ui/state/state.dart';

abstract class ReactiveValue<T> extends ChangeNotifier
    implements ValueListenable<T> {}

class Prop<T> extends ReactiveValue<T> {
  T _value;
  Prop(this._value);

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
class Const<T> extends ReactiveValue<T> {
  final T _value;

  Const(this._value);

  @override
  T get value => _value;
}
