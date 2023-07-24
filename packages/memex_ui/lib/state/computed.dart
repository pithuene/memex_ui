import 'package:memex_ui/state/state.dart';

class Computed<T> extends ReactiveValue<T> with ReactiveListener {
  late T _value;
  T Function() f;

  Computed(this.f) {
    _value = _computeValue();
  }

  @override
  T get value {
    ReactiveListener.currentContextListener?.listenTo(this);
    return _value;
  }

  @override
  void onDependencyChange() {
    _value = _computeValue();
    notifyListeners();
  }

  T _computeValue() {
    T? result;
    executeInContext(() {
      result = f();
    });
    return result!;
  }
}
