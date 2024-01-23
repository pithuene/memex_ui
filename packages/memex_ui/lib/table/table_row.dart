import 'dart:ui';

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
    required this.isActive,
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

  /// When the table is not active, the selection color is grey.
  final ReactiveValue<bool> isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        data.select(TableSelection(key: row.key, value: row.value));
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 75),
        padding: fullWidthHighlight
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 8),
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
              isActive: isActive,
              columnWidths: columnWidths,
              childrenBuilder: (context) => colDefs
                  .map(
                    (colDef) => colDef
                        .cellBuilder(context, row.value, isSelected)
                        .alignment(switch (colDef.alignment) {
                          ColumnAlignment.start => Alignment.centerLeft,
                          ColumnAlignment.center => Alignment.center,
                          ColumnAlignment.end => Alignment.centerRight,
                        })
                        .height(rowHeight)
                        .padding(horizontal: 10),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

/// Add selection and even / odd highlighting to table rows
class _RowHighlight extends ReactiveWidget {
  const _RowHighlight({
    required this.isActive,
    required this.hasEvenRowHighlight,
    required this.fullWidthHighlight,
    required this.isSelected,
    required this.columnWidths,
    required this.childrenBuilder,
  });

  final bool hasEvenRowHighlight;
  final bool fullWidthHighlight;

  /// When the table is not active, the selection color is grey.
  final ReactiveValue<bool> isActive;

  final bool isSelected;
  final Map<int, TableColumnWidth> columnWidths;
  final List<Widget> Function(BuildContext) childrenBuilder;

  @override
  Widget build(BuildContext context) {
    assert(
      !(isActive.value == false && hasEvenRowHighlight),
      "Inactive table with even row highlight will look terrible.",
    );

    Decoration? decoration;
    TextStyle textStyle = MemexTypography.body
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
        color: (isActive.value) ? MemexColor.selection : MemexColor.shade,
        borderRadius: fullWidthHighlight
            ? null
            : const BorderRadius.all(Radius.circular(5)),
      );
      if (isActive.value) {
        textStyle = textStyle.copyWith(color: MemexColor.white);
      }
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
