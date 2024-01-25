import 'package:memex_ui/memex_ui.dart';
import './table_header.dart';
import './table_row.dart';

/// A scrollable data table with sorting and selection.
class TableView<T> extends ReactiveWidget {
  const TableView({
    super.key,
    this.scrollController,
    required this.rowHeight,
    required this.dataSource,
    this.onRowTap,
    this.showHeader = true,
    this.showEvenRowHighlight = true,
    this.isActive = const Const(true),
    this.canReceiveInput = const Const(true),
    this.fullWidthHighlight = false,
  });

  /// The height of every row.
  final double rowHeight;

  /// Whether to highlight every other row for
  /// better readability in large tables.
  final bool showEvenRowHighlight;

  /// Whether the table header is visible.
  final bool showHeader;

  /// Whether the row highlight covers the full width,
  /// in which case it is also not rounded.
  final bool fullWidthHighlight;

  /// When the table is not active, the selection color is grey.
  final ReactiveValue<bool> isActive;

  /// Whether the table can receive input through the [GestureDetector].
  /// If false, tap events are not handled.
  final ReactiveValue<bool> canReceiveInput;

  /// Called when a table row is tapped, after the selection is changed.
  final Function(int, TableValue<T>)? onRowTap;

  /// Optionally override the scrollController.
  final ScrollController? scrollController;
  final TableDatasource<T> dataSource;

  static TableView<T> of<T>(BuildContext context) =>
      context.findAncestorWidgetOfExactType<TableView<T>>()!;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TableOrder<T>?>(
      initialData: dataSource.order,
      stream: dataSource.onOrderChanged,
      builder: (context, order) => ReactiveBuilder(
        () => Column(
          children: [
            if (showHeader)
              TableHeader<T>(
                order: order.data,
                columnHeaderClicked: (colDef) {
                  if (colDef == order.data?.column) {
                    dataSource.reverseOrderDirection();
                  } else {
                    dataSource.orderBy(TableOrder(column: colDef));
                  }
                },
              ),
            StreamBuilder<void>(
              initialData: null,
              stream: dataSource.onDataChanged,
              builder: (context, _) => ListView.builder(
                controller: scrollController,
                itemCount: dataSource.rowCount,
                itemExtent: rowHeight,
                itemBuilder: (context, index) => TableViewRow(
                  index: index,
                  row: dataSource.getRowValue(index),
                ),
              ),
            ).expanded(),
          ],
        ),
      ),
    );
  }
}
