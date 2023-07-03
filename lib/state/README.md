State Management
================

A Flutter [reactive state management solution](https://docs.flutter.dev/data-and-backend/state-mgmt/options) based on a modified `ValueNotifier` called `Prop` and a new widget base class `ReactiveWidget`.
When the value of a `Prop` is read while executing the `build` function of a `ReactiveWidget`, the `Prop` is automatically added to the widget's dependencies.
If any of the dependencies of a `ReactiveWidget` change, the widget will be rebuilt.

Simple Example
--------------

``` dart
class MyWidget extends ReactiveWidget {
  final Prop<int> state = Prop(0);
  MyWidget({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          state.value++;
        },
        child: Text(state.value.toString()),
      );
}
```

The state is wrapped in a `Prop` and the widget extends `ReactiveWidget` instead of `StatelessWidget`.
When the `build` function runs, the `state.value` getter is called, which adds `state` to the widget as a dependency.
Now, when the setter of `state.value` is called in `onTap`, the widget is notified of the change and rebuilds.

Note that declaring state in a `ReactiveWidget` as shown is generally not a good idea, since a rebuild of the parent widget will replace the `ReactiveWidget` with a new copy, resetting the state.

Something else to be aware of is that `Prop` can only notify it's listeners when the setter is called.
If you call a method on the object inside a `Prop` that changes it internally, the setter will never be called and no rebuild will occur.
The classic example of this is a `List`, if you use a `Prop<List<int>> list` and call `list.value.add(123)`, there will be no rebuild.
A simple solution is to use a `Prop<IList<int>>` instead.

`ReactiveBuilder`
---------------

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
