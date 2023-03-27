import 'dart:ui';
import 'dart:math';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/table/table_selection.dart';

class MillerColumns<K, V> extends StatefulWidget {
  /// Hook to extend the keyboard controls.
  final void Function(RawKeyEvent, MillerColumnsState)? onKey;

  /// Get the children of the node at a given path.
  /// If the node is a leaf, return an empty [Iterable].
  final Future<Iterable<V>> Function(IList<K>) getChildren;

  /// Builder to display a given node.
  final Widget Function(BuildContext, V) rowBuilder;

  /// Gets a selected node and returns the key
  /// which should be appended to the path to point to it.
  final K Function(V) toKey;

  /// Called when a leaf is selected.
  final void Function(V)? onSelect;

  final List<K>? initialPath;

  const MillerColumns({
    super.key,
    this.onKey,
    this.onSelect,
    this.initialPath,
    required this.getChildren,
    required this.rowBuilder,
    required this.toKey,
  });

  @override
  State<StatefulWidget> createState() => MillerColumnsState<K, V>();
}

class MillerColumnsState<K, V> extends State<MillerColumns<K, V>> {
  final FocusNode focusNode = FocusNode();
  IList<K> path = <K>[].lockUnsafe;

  List<List<V>> columns = [];

  List<V> get parentColumn =>
      columns.length >= 2 ? columns[columns.length - 2] : [];
  List<V> get currentColumn => columns.isNotEmpty ? columns.last : [];

  // The child column is only a preview and is therefore handled separately.
  List<V> childColumn = [];

  Future<void> updateChildColumn() async {
    childColumn = [];
    childColumn = (await widget.getChildren(path)).toList();
    childrenDatasource.dataChanged();
  }

  late TableDatasource<V> parentDatasource = TableDatasource<V>(
    colDefs: [
      ColumnDefinition(
        label: "",
        cellBuilder: widget.rowBuilder,
      )
    ],
    getRowCount: () => parentColumn.length,
    getRowValue: (index) => TableValue(
      key: ValueKey(widget.toKey(parentColumn[index])),
      value: parentColumn[index],
    ),
  );
  late TableDatasource<V> currentDatasource = TableDatasource<V>(
    colDefs: [
      ColumnDefinition(
        label: "",
        cellBuilder: widget.rowBuilder,
      )
    ],
    getRowCount: () => currentColumn.length,
    getRowValue: (index) => TableValue(
      key: ValueKey(widget.toKey(currentColumn[index])),
      value: currentColumn[index],
    ),
  );
  late TableDatasource<V> childrenDatasource = TableDatasource<V>(
    colDefs: [
      ColumnDefinition(
        label: "",
        cellBuilder: widget.rowBuilder,
      )
    ],
    getRowCount: () => childColumn.length,
    getRowValue: (index) => TableValue(
      key: ValueKey(widget.toKey(childColumn[index])),
      value: childColumn[index],
    ),
  );

  @override
  void initState() {
    super.initState();
    path = (widget.initialPath != null)
        ? widget.initialPath!.lock
        : <K>[].lockUnsafe;
    initColumns();
    focusNode.requestFocus();
  }

  Future<void> initColumns() async {
    for (int i = 0; i < path.length; i++) {
      columns.add(
        (await widget.getChildren(path.sublist(0, i))).toList(),
      );
    }
    currentDatasource.selectWhere(
      (row) => widget.toKey(row.value) == path.last,
    );
    await updateChildColumn();
    parentDatasource.dataChanged();
    currentDatasource.dataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: focusNode,
      onKey: (event) async {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyH) {
            if (path.isEmpty) return;
            path = path.removeLast();
            childColumn = columns.removeLast();
            parentDatasource.dataChanged();
            parentDatasource.selectWhere(
              (row) => widget.toKey(row.value) == path[path.length - 2],
            );
            currentDatasource.dataChanged();
            currentDatasource.selectWhere(
              (row) => widget.toKey(row.value) == path.last,
            );
            return;
          } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
            if (childColumn.isEmpty) {
              if (widget.onSelect != null) {
                widget.onSelect!(currentDatasource.selectedRows.single);
              }
              return;
            }
            path = path.add(
              widget.toKey(currentDatasource.selectedRows.single),
            );
            columns.add(childColumn);
            updateChildColumn();
            parentDatasource.dataChanged();
            parentDatasource.selectWhere(
              (row) => widget.toKey(row.value) == path[path.length - 2],
            );
            currentDatasource.dataChanged();
            currentDatasource.selectIndex(0);
            return;
          } else if (event.logicalKey == LogicalKeyboardKey.keyJ) {
            currentDatasource.moveSelectionDown();
            path = path.replace(
              path.length - 1,
              widget.toKey(currentDatasource.selectedRows.single),
            );
            updateChildColumn();
            return;
          } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
            currentDatasource.moveSelectionUp();
            path = path.replace(
              path.length - 1,
              widget.toKey(currentDatasource.selectedRows.single),
            );
            updateChildColumn();
            return;
          }
        }
        if (widget.onKey != null) widget.onKey!(event, this);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 80),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: const BorderRadius.all(Radius.circular(5.0)),
            border: Border.all(color: Colors.black.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TableView<V>(
                  rowHeight: 24,
                  dataSource: parentDatasource,
                  showHeader: false,
                  fullWidthHighlight: true,
                  showEvenRowHighlight: false,
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: TableView<V>(
                    rowHeight: 24,
                    dataSource: currentDatasource,
                    showHeader: false,
                    fullWidthHighlight: true,
                    showEvenRowHighlight: false,
                  ),
                ),
              ),
              Expanded(
                child: TableView<V>(
                  rowHeight: 24,
                  dataSource: childrenDatasource,
                  showHeader: false,
                  fullWidthHighlight: true,
                  showEvenRowHighlight: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
