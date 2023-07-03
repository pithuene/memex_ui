import 'package:memex_ui/state/state.dart';

class PropList<T> extends Prop<List<ReactiveValue<T>>> {
  PropList(List<ReactiveValue<T>> items) : super(items);

  void add(ReactiveValue<T> item) {
    super.value.add(item);
    super.notifyListeners();
  }

  Iterable<T> get values => value.map((item) => item.value);

  ReactiveValue<T> operator [](int index) => super.value[index];
}

/// A [List] of [Prop]s of type T.
/// To use other [ReactiveValue]s than [Prop]s use [PropList].
///
/// Accessing an item using the index operator bypasses the lists
/// value getter, so only changes of that item trigger a context rebuild,
/// not changes of the list itself.
class Props<T> extends Prop<List<Prop<T>>> {
  Props(Iterable<T> items) : super(items.map((item) => Prop(item)).toList());

  void add(T item) {
    value.add(Prop(item));
    notifyListeners();
  }

  void removeAt(int index) {
    value.removeAt(index);
    notifyListeners();
  }

  Iterable<T> get values => value.map((item) => item.value);

  int get length => value.length;

  T operator [](int index) => _value[index].value;
}

class PropList<T> extends Prop<List<ReactiveValue<T>>> {
  PropList(List<ReactiveValue<T>> items) : super(items);

  void add(ReactiveValue<T> item) {
    super.value.add(item);
    super.notifyListeners();
  }

  Iterable<T> get values => value.map((item) => item.value);

  ReactiveValue<T> operator [](int index) => super.value[index];
}

/// A [List] of [Prop]s of type T.
/// To use other [ReactiveValue]s than [Prop]s use [PropList].
///
/// Accessing an item using the index operator bypasses the lists
/// value getter, so only changes of that item trigger a context rebuild,
/// not changes of the list itself.
class Props<T> extends Prop<List<Prop<T>>> {
  Props(Iterable<T> items) : super(items.map((item) => Prop(item)).toList());

  void add(T item) {
    value.add(Prop(item));
    notifyListeners();
  }

  void removeAt(int index) {
    value.removeAt(index);
    notifyListeners();
  }

  Iterable<T> get values => value.map((item) => item.value);

  int get length => value.length;

  T operator [](int index) => _value[index].value;
}
