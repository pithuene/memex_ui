import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef Prop<T> = ValueNotifier<T>;
typedef ReadonlyProp<T> = ValueListenable<T>;

typedef BuilderWithContext<T> = Widget Function(BuildContext, T);
typedef BuilderWithoutContext<T> = Widget Function(T);

/// Get the value out of a [ValueListenable]
class $<T> extends StatelessWidget {
  const $.$(this._listenable, this._builderWithContext, {super.key})
      : _builderWithoutContext = null;

  const $(this._listenable, this._builderWithoutContext, {super.key})
      : _builderWithContext = null;

  final ValueListenable<T> _listenable;
  final BuilderWithContext<T>? _builderWithContext;
  final BuilderWithoutContext<T>? _builderWithoutContext;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: _listenable,
      builder: (BuildContext context, T value, _) => _builderWithContext != null
          ? _builderWithContext!(context, value)
          : _builderWithoutContext!(value),
    );
  }
}

/// A listenable property which depends on a list of [dependencies].
/// When any of the [dependencies] changes,
/// the value changes and all listeners are notified.
/// Make sure to list all used properties as dependencies!
class ComputedProp<T> extends ChangeNotifier implements ValueListenable<T> {
  ComputedProp(
    this.transform,
    this.dependencies,
  ) : super() {
    // If any dependency changes, notify listeners.
    _dependencyListener = () {
      notifyListeners();
    };
    for (ValueListenable dependency in dependencies) {
      dependency.addListener(_dependencyListener);
    }
  }

  late final void Function() _dependencyListener;
  final List<ValueListenable> dependencies;
  final T Function() transform;

  @override
  void dispose() {
    for (ValueListenable dependency in dependencies) {
      dependency.removeListener(_dependencyListener);
    }
    super.dispose();
  }

  @override
  T get value => transform();

  @override
  String toString() => '${describeIdentity(this)}($value)';
}
