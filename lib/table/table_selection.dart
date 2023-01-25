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
class TableSelectionChange {
  const TableSelectionChange(
    this.oldSelection,
    this.newSelection,
  );

  final TableSelection? oldSelection;
  final TableSelection? newSelection;
}
