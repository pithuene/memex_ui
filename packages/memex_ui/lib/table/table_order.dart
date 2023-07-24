import 'package:memex_ui/memex_ui.dart';

enum TableOrderDirection {
  ascending,
  descending,
}

class TableOrder<T> {
  TableOrder({
    required this.column,
    this.direction = TableOrderDirection.descending,
  });

  ColumnDefinition<T> column;
  TableOrderDirection direction;

  void reverseDirection() {
    if (direction == TableOrderDirection.ascending) {
      direction = TableOrderDirection.descending;
    } else {
      direction = TableOrderDirection.ascending;
    }
  }
}
