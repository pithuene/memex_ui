# Memex Data

A Flutter [reactive state management solution](https://docs.flutter.dev/data-and-backend/state-mgmt/options) based on a modified `ValueNotifier` called `Prop` and a new widget base class `ReactiveWidget`.

When the value of a `Prop` is read while executing the `build` function of a `ReactiveWidget`, the `Prop` is automatically added to the widget's dependencies.
If any of the dependencies of a `ReactiveWidget` change, the widget will be rebuilt.

## Components

Reactivity in the library is implemented using two key components: `ReactiveValue` and `ReactiveListener`.

### ReactiveValue

The backbone of reactivity is the `ReactiveValue`. It comes in two primary forms:

- `Prop`: Encapsulates a single value and provides both a getter and a setter.
- `Const`: For when a `ReactiveValue` is expected, but the value remains constant. It implements `ReactiveValue` but lacks a setter. It also has a const constructor so it can be used as a default constructor parameter.

### ReactiveListener

The primary use of `ReactiveListener` is in the form of `ReactiveWidget`. Unlike traditional `StatelessWidgets`, you extend your widgets from `ReactiveWidget`.

- `ReactiveWidget`: Any `ReactiveValue` accessed within the `build` function of a `ReactiveWidget` is automatically added to the widget's dependencies. Consequently, the widget will be rebuilt whenever any of its dependencies change. If extending `ReactiveWidget` isn't feasible, you can utilize `ReactiveBuilder` to wrap your widgets.

### Computed

Another feature is the `Computed` class, which allows the creation of values derived from other `ReactiveValues`. These values are recalculated whenever their inputs change.

Note that you can often use a regular getter function instead of a `Computed` property. A simple function that accesses the `ReactiveValue`s will trigger the reactivity just the same.
The only difference is that `Computed` will re-evaluate the result on each dependency change, while a regular function will evaluate on each access.

### State Management

In addition to reactivity, our library simplifies state management within your widget tree.

- `StateProvider`: This class is used to place state within the widget tree. Once defined, the state's value can be conveniently accessed using the `BuildContext.state<M>` function.


## Usage

First, define a class that will hold your state.
Use `Prop` to wrap the values to which you want the UI to react.

``` dart
class MyState {
  final Prop<int> count = Prop(0);
}
```

Then, create a `StateProvider` to place the state within the widget tree.

``` dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StateProvider(
      models: [
        () => MyState(),
      ],
      child: MaterialApp(
        home: MyWidget(),
      ),
    );
  }
}
```

Now, in your widget, you extend `ReactiveWidget` and access the state using `BuildContext.state`.

``` dart
class MyWidget extends ReactiveWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.state<MyState>();
    return GestureDetector(
      onTap: () {
        state.count.value++;
      },
      child: Text(state.count.value.toString()),
    );
  }
}
```

When the `build` function runs, the `count.value` getter is called, which adds `count` to the widget as a dependency.
Now, when the setter of `count.value` is called in `onTap`, the widget is notified of the change and rebuilds.

Something to be aware of is that `Prop` can only notify it's listeners when the setter is called.
If you call a method on the object inside a `Prop` that changes it internally, the setter will never be called and no rebuild will occur.
The classic example of this is a `List`.
If you use a `Prop<List<int>> list` and call `list.value.add(123)`, there will be no rebuild.
A simple solution is to use a `Prop<IList<int>>` instead.
Maybe the library will also provide reactive collections in the future.

## `ReactiveBuilder`

In general, accessing the value of a `Prop` in a `build` function will rebuild the next `ReactiveWidget` up in the widget tree.
This is also the case if the access doesn't happen directly in a `ReactiveWidget`.

Sometimes you may want to optimize by introducing a rebuild boundary to limit rebuilds to a part of a widget's children.
`ReactiveBuilder` can be used to achieve this:

``` dart
class MyWidget extends ReactiveWidget {
  final Prop<int> state = Prop(0);
  MyWidget({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          state.value++;
        },
        child: Column(
          children: [
            const Text("Not rebuilt"),
            ReactiveBuilder(() => Text(state.value.toString())),
          ],
        ),
      );
}
```
