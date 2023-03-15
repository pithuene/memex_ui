import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef Prop<T> = ValueNotifier<T>;
typedef ReadonlyProp<T> = ValueListenable<T>;

typedef BuilderWithContext<T> = Widget Function(BuildContext, T);
typedef BuilderWithoutContext<T> = Widget Function(T);

/// Listen to a [Prop] and rebuild part of the UI when its value changes.
class $<T> extends StatelessWidget {
  /// The default constructor.
  /// Listen to a [Prop] with a builder which doesn't require the [BuildContext].
  /// If the [BuildContext] is required, use the [withContext] constructor.
  const $(this._listenable, this._builderWithoutContext, {super.key})
      : _builderWithContext = null;

  /// Listen to a [Prop] with a builder which requires the [BuildContext].
  const $.withContext(this._listenable, this._builderWithContext, {super.key})
      : _builderWithoutContext = null;

  /// The [Prop] which triggers this widget to rebuild.
  final ReadonlyProp<T> _listenable;

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
///
/// Make sure to list all used properties as dependencies!
class ComputedProp<T> extends ChangeNotifier implements ReadonlyProp<T> {
  ComputedProp(
    this.compute,
    this.dependencies,
  ) {
    // If any dependency changes, notify listeners.
    _dependencyListener = () {
      notifyListeners();
    };
    for (ValueListenable dependency in dependencies) {
      dependency.addListener(_dependencyListener);
    }
  }

  late final void Function() _dependencyListener;

  /// The list of dependencies which trigger this property to be recomputed.
  final List<ValueListenable> dependencies;

  final T Function() compute;

  @override
  void dispose() {
    for (ValueListenable dependency in dependencies) {
      dependency.removeListener(_dependencyListener);
    }
    super.dispose();
  }

  @override
  T get value => compute();

  @override
  String toString() => '${describeIdentity(this)}($value)';
}
