import 'package:flutter/widgets.dart';

@immutable
class TableSelection<T> {
  const TableSelection({
    required this.key,
    required this.value,
  });

  final Key key;
  final T value;
}

@immutable
class TableSelectionChange<T> {
  const TableSelectionChange(
    this.oldSelection,
    this.newSelection,
    this.newIndex,
  );

  final TableSelection<T>? oldSelection;
  final TableSelection<T>? newSelection;

  /// The index of the new selection.
  /// This is independant of the [TableSelection] because it is only valid
  /// immediatly after the selection change. After entries are inserted,
  /// the order is changed, etc., the index may not be correct anymore.
  final int newIndex;
}
