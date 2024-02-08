import 'package:flutter/foundation.dart';
import './reactive_listener.dart';
import './reactive_value.dart';

/// A [Computed] value can use various [ReactiveValue]s in it's calculation,
/// and will update if any of the dependencies change.
///
/// You only need [Computed] if you want to perform the recalculation on
/// every dependency change instead of on every access. Otherwise, just use
/// a normal function that accesses the [ReactiveValue]s internally.
///
/// Example:
///
/// Prop<String> fullName = Prop("John Smith");
/// late Computed<String> firstNameComp = Computed(() => fullName().split(" ").first);
/// String get firstNameFunc = fullName().split(" ").first;
///
/// Using firstNameFunc, the first name will be recomputed on every access,
/// using firstNameComp, the first name will be recomputed whenever the full name changes.
class Computed<T> extends ChangeNotifier
    with ReactiveListener
    implements ReactiveValue<T> {
  T? _value;
  T Function() f;

  Computed(this.f) {
    _updateValue();
  }

  @override
  T get value {
    ReactiveListener.currentContextListener?.listenTo(this);
    return _value!;
  }

  @override
  void onDependencyChange() {
    _updateValue();
    notifyListeners();
  }

  /// Recompute the value and return whether it changed.
  bool _updateValue() {
    T? result;
    executeInContext(() {
      result = f();
    });
    bool valueChanged = result != _value;
    if (valueChanged) {
      _value = result!;
    }
    return valueChanged;
  }
}
