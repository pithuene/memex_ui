import 'package:flutter/widgets.dart';

enum ColumnAlignment {
  start,
  center,
  end,
}

class ColumnDefinition<T> {
  const ColumnDefinition({
    required this.label,
    required this.cellBuilder,
    this.width = const FlexColumnWidth(),
    this.alignment = ColumnAlignment.start,
  });

  final String label;
  final TableColumnWidth width;
  final ColumnAlignment alignment;
  final Widget Function(BuildContext, T, bool) cellBuilder;
}
