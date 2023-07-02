import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/table/table_selection.dart';

class TableViewRow<T> extends StatelessWidget {
  const TableViewRow({
    super.key,
    required this.index,
    required this.columnWidths,
    required this.colDefs,
    required this.row,
    required this.rowHeight,
    required this.data,
    this.fullWidthHighlight = false,
    bool showEvenRowHighlight = true,
  }) : hasEvenRowHighlight = (showEvenRowHighlight) ? index % 2 == 1 : false;

  final Map<int, TableColumnWidth> columnWidths;
  final List<ColumnDefinition<T>> colDefs;
  final TableValue<T> row;

  final double rowHeight;

  final int index;

  final TableDatasource<T> data;

  final bool hasEvenRowHighlight;
  final bool fullWidthHighlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        data.select(TableSelection(key: row.key, value: row.value));
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: fullWidthHighlight
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 10),
        child: StreamBuilder<TableSelectionChange>(
          stream: data.onSelectionChanged.where((change) =>
              change.oldSelection?.key == row.key ||
              change.newSelection?.key == row.key),
          builder: (context, selection) {
            final bool isSelected = data.selectedKeys.contains(row.key);
            if (isSelected && context.findRenderObject() != null) {
              Scrollable.ensureVisible(
                context,
                alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
              );
              Scrollable.ensureVisible(
                context,
                alignmentPolicy:
                    ScrollPositionAlignmentPolicy.keepVisibleAtStart,
              );
            }
            return _RowHighlight(
              hasEvenRowHighlight: hasEvenRowHighlight,
              fullWidthHighlight: fullWidthHighlight,
              isSelected: isSelected,
              columnWidths: columnWidths,
              childrenBuilder: (context) => colDefs.map((colDef) {
                final AlignmentGeometry alignmentGeometry =
                    (colDef.alignment == ColumnAlignment.start)
                        ? Alignment.centerLeft
                        : (colDef.alignment == ColumnAlignment.center)
                            ? Alignment.center
                            : Alignment.centerRight;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox.fromSize(
                    size: Size(0, rowHeight),
                    child: Align(
                      alignment: alignmentGeometry,
                      child: colDef.cellBuilder(context, row.value),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

/// Add selection and even / odd highlighting to table rows
class _RowHighlight extends StatelessWidget {
  const _RowHighlight({
    required this.hasEvenRowHighlight,
    required this.fullWidthHighlight,
    required this.isSelected,
    required this.columnWidths,
    required this.childrenBuilder,
  });

  final bool hasEvenRowHighlight;
  final bool fullWidthHighlight;
  final bool isSelected;
  final Map<int, TableColumnWidth> columnWidths;
  final List<Widget> Function(BuildContext) childrenBuilder;

  @override
  Widget build(BuildContext context) {
    Decoration? decoration;
    TextStyle textStyle = MacosTheme.of(context)
        .typography
        .body
        .copyWith(fontFeatures: [const FontFeature.tabularFigures()]);
    if (hasEvenRowHighlight && !isSelected) {
      decoration = BoxDecoration(
        color: MemexColor.shade,
        borderRadius: fullWidthHighlight
            ? null
            : const BorderRadius.all(Radius.circular(5)),
      );
    } else if (isSelected) {
      decoration = BoxDecoration(
        color: MacosTheme.of(context).primaryColor,
        borderRadius: fullWidthHighlight
            ? null
            : const BorderRadius.all(Radius.circular(5)),
      );
      textStyle = textStyle.copyWith(color: MacosColors.white);
    }
    return DefaultTextStyle(
      style: textStyle,
      child: Builder(
        builder: (context) => Table(
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: decoration,
              children: childrenBuilder(context),
            ),
          ],
        ),
      ),
    );
  }
}
