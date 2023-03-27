import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:memex_ui/table/table_order.dart';
import './table_header.dart';
import './table_row.dart';
import './table_datasource.dart';

/// A scrollable data table with sorting and selection.
class TableView<T> extends StatelessWidget {
  const TableView({
    super.key,
    this.scrollController,
    required this.rowHeight,
    required this.dataSource,
    this.showHeader = true,
    this.showEvenRowHighlight = true,
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

  /// Optionally override the scrollController.
  final ScrollController? scrollController;
  final TableDatasource<T> dataSource;

  @override
  Widget build(BuildContext context) {
    /// A map from column index to its TableColumnWidth.
    /// Every Table widget needs this, so it is created once and cached here.
    final Map<int, TableColumnWidth> columnWidths =
        dataSource.colDefs.map((colDef) => colDef.width).toList().asMap();

    return StreamBuilder<TableOrder<T>?>(
      initialData: dataSource.order,
      stream: dataSource.onOrderChanged,
      builder: (context, order) => Column(
        children: [
          ...showHeader
              ? [
                  TableHeader<T>(
                    colDefs: dataSource.colDefs,
                    order: order.data,
                    columnHeaderClicked: (colDef) {
                      if (colDef == order.data?.column) {
                        dataSource.reverseOrderDirection();
                      } else {
                        dataSource.orderBy(TableOrder(column: colDef));
                      }
                    },
                  )
                ]
              : [],
          Expanded(
            child: StreamBuilder<void>(
              initialData: Null,
              stream: dataSource.onDataChanged,
              builder: (context, _) => ListView.builder(
                controller: scrollController,
                itemCount: dataSource.rowCount,
                itemExtent: rowHeight,
                itemBuilder: (context, index) {
                  return TableViewRow(
                    data: dataSource,
                    index: index,
                    rowHeight: rowHeight,
                    columnWidths: columnWidths,
                    colDefs: dataSource.colDefs,
                    row: dataSource.getRowValue(index),
                    showEvenRowHighlight: showEvenRowHighlight,
                    fullWidthHighlight: fullWidthHighlight,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
