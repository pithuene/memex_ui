import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:memex_ui/table/table_columns.dart';
import 'package:memex_ui/table/table_order.dart';
import 'package:memex_ui/table/table_selection.dart';

/// A combination of a row [value] and a persistent identifier [key] for the row.
@immutable
class TableValue<T> {
  const TableValue({
    required this.key,
    required this.value,
  });

  /// A persistent identifier for this row.
  ///
  /// If you select a row and change the data or order,
  /// the key is how the table knows which row was selected.
  ///
  /// If you never change the object instances displayed by the table,
  /// use an `ObjectKey` of the value object.
  /// Normally, this should be a ValueKey of some unique attribute of the row value.
  /// If you never even change the order, you could also use a
  /// ValueKey of the index.
  final Key key;

  /// The row value.
  ///
  /// Passed to [rowBuilder] to build a rows cell widgets.
  final T value;
}

/// The state of a [TableView].
///
/// Supplies the data to a [TableView] and serves as a handle to execute
/// operations on the table.
class TableDatasource<T> {
  TableDatasource({
    this.changeOrder,
    required List<ColumnDefinition<T>> colDefs,
    required this.getRowCount,
    required this.getRowValue,
  })  : _colDefs = colDefs,
        _rowCount = getRowCount();

  // Various streams to enable partial rebuilding using StreamBuilder
  final StreamController<void> _dataChangedController =
      StreamController<void>.broadcast();
  Stream<void> get onDataChanged => _dataChangedController.stream;

  final StreamController<TableOrder<T>?> _orderChangedController =
      StreamController<TableOrder<T>?>.broadcast();
  Stream<TableOrder<T>?> get onOrderChanged => _orderChangedController.stream;

  final StreamController<TableSelectionChange> _selectionChangedController =
      StreamController<TableSelectionChange>.broadcast();
  Stream<TableSelectionChange> get onSelectionChanged =>
      _selectionChangedController.stream;

  // TODO: Add functions to change columns (if possible with animations)

  /// Define which columns are shown.
  final List<ColumnDefinition<T>> _colDefs;
  List<ColumnDefinition<T>> get colDefs => _colDefs;

  // By what column and in what direction the table is ordered.
  TableOrder<T>? order;

  // Callback to update the row count.
  final int Function() getRowCount;

  /// The number of rows in the table.
  /// Limits with which indices `getRow` is called.
  int _rowCount = 0;

  int get rowCount => _rowCount;

  /// The main function through which data is fed into the table.
  /// You need to maintain some order from index (between 0 and rowCount)
  /// to rows.
  /// This function gets called when the row at a given index is rebuilt.
  final TableValue<T> Function(int index) getRowValue;

  /// A function called when the table order should change.
  ///
  /// Should either reject the order (by returning `false`),
  /// or change the order of items returned by [getRowValue] according to
  /// the given [TableOrder].
  final bool Function(TableOrder<T>?)? changeOrder;

  // TODO: Allow selecting multiple rows.

  /// The current selection of the table.
  TableSelection? _selection;

  /// Change which rows are selected.
  ///
  /// Updates the internal selection and rebuilds
  /// the selected and previously selected rows.
  void select(TableSelection<T>? selection) {
    final selectionChange = TableSelectionChange(_selection, selection);
    _selection = selection;
    _selectionChangedController.add(selectionChange);
  }

  List<T> get selectedRows => _selection == null ? [] : [_selection!.value];

  List<Key> get selectedKeys => _selection == null ? [] : [_selection!.key];

  int? _findRowKeyIndex(Key? rowKey) {
    int currentSelectedRowIndex = 0;
    while (getRowValue(currentSelectedRowIndex).key != rowKey) {
      currentSelectedRowIndex++;
    }
    if (currentSelectedRowIndex < getRowCount()) {
      return currentSelectedRowIndex;
    } else {
      return null;
    }
  }

  void moveSelectionDown() {
    if (getRowCount() == 0) return;
    if (_selection == null) {
      TableValue<T> firstRow = getRowValue(0);
      select(TableSelection(key: firstRow.key, value: firstRow.value));
    } else {
      int? currentSelectedRowIndex = _findRowKeyIndex(_selection?.key);
      if (currentSelectedRowIndex != null &&
          currentSelectedRowIndex < getRowCount() - 1) {
        TableValue<T> nextRow = getRowValue(currentSelectedRowIndex + 1);
        select(TableSelection(key: nextRow.key, value: nextRow.value));
      }
    }
  }

  void moveSelectionUp() {
    if (getRowCount() == 0) return;
    if (_selection == null) {
      TableValue<T> lastRow = getRowValue(getRowCount() - 1);
      select(TableSelection(key: lastRow.key, value: lastRow.value));
    } else {
      int? currentSelectedRowIndex = _findRowKeyIndex(_selection?.key);
      if (currentSelectedRowIndex != null && currentSelectedRowIndex > 0) {
        TableValue<T> nextRow = getRowValue(currentSelectedRowIndex - 1);
        select(TableSelection(key: nextRow.key, value: nextRow.value));
      }
    }
  }

  /// Notify the view about a change in the table order.
  ///
  /// Emits an event in [onOrderChanged].
  _updateOrder() {
    // Call the callback first, so the actual data is reordered.
    if (changeOrder != null) {
      changeOrder!(order);
    }
    // Update the view through the [StreamBuilder] afterwards.
    _orderChangedController.add(order);
  }

  /// Notify the table about new or modified data.
  ///
  /// Call this after every data change you want to see,
  /// if you don't call this function, the new data may not be shown.
  /// Only call this function once after a series of data changes,
  /// since it causes most of the table to rebuild, which is expensive.
  dataChanged() {
    _rowCount = getRowCount();
    _dataChangedController.add(Null);
  }

  /// Toggle between ascending and descending order.
  void reverseOrderDirection() {
    order?.reverseDirection();
    _updateOrder();
  }

  void orderBy(TableOrder<T>? newOrder) {
    order = newOrder;
    _updateOrder();
  }
}
