import 'dart:ui';

import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/table/table_selection.dart';

class TableViewRow<T> extends StatelessWidget {
  const TableViewRow({
    super.key,
    required this.index,
    required this.row,
  });

  final TableValue<T> row;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tv = TableView.of<T>(context);

    return GestureDetector(
      onTap: () {
        if (tv.canReceiveInput.value) {
          tv.dataSource.select(
            TableSelection(key: row.key, value: row.value),
            index,
          );
          if (tv.onRowTap != null) tv.onRowTap!(index, row);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 75),
        padding: tv.fullWidthHighlight
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 8),
        child: StreamBuilder<TableSelectionChange>(
          stream: tv.dataSource.onSelectionChanged.where((change) =>
              change.oldSelection?.key == row.key ||
              change.newSelection?.key == row.key),
          builder: (context, selection) {
            final bool isSelected =
                tv.dataSource.selectedKeys.contains(row.key);
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
            return _RowHighlight<T>(
              isSelected: isSelected,
              hasEvenRowHighlight:
                  (tv.showEvenRowHighlight) ? index % 2 == 1 : false,
              childrenBuilder: (context) => tv.dataSource.colDefs
                  .map(
                    (colDef) => colDef
                        .cellBuilder(context, row.value, isSelected)
                        .alignment(switch (colDef.alignment) {
                          ColumnAlignment.start => Alignment.centerLeft,
                          ColumnAlignment.center => Alignment.center,
                          ColumnAlignment.end => Alignment.centerRight,
                        })
                        .height(tv.rowHeight)
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
class _RowHighlight<T> extends ReactiveWidget {
  const _RowHighlight({
    required this.isSelected,
    required this.childrenBuilder,
    required this.hasEvenRowHighlight,
  });

  final bool isSelected;
  final List<Widget> Function(BuildContext) childrenBuilder;

  /// Whether this specific row is highlighted.
  final bool hasEvenRowHighlight;

  @override
  Widget build(BuildContext context) {
    final TableView<T> tv = TableView.of<T>(context);

    assert(
      !(tv.isActive.value == false && hasEvenRowHighlight),
      "Inactive table with even row highlight will look terrible.",
    );

    Decoration? decoration;
    TextStyle textStyle = MemexTypography.body
        .copyWith(fontFeatures: [const FontFeature.tabularFigures()]);
    if (hasEvenRowHighlight && !isSelected) {
      decoration = BoxDecoration(
        color: MemexColor.shade,
        borderRadius: tv.fullWidthHighlight
            ? null
            : const BorderRadius.all(Radius.circular(5)),
      );
    } else if (isSelected) {
      decoration = BoxDecoration(
        color: (tv.isActive.value) ? MemexColor.selection : MemexColor.shade,
        borderRadius: tv.fullWidthHighlight
            ? null
            : const BorderRadius.all(Radius.circular(5)),
      );
      if (tv.isActive.value) {
        textStyle = textStyle.copyWith(color: MemexColor.white);
      }
    }
    return DefaultTextStyle(
      style: textStyle,
      child: Builder(
        builder: (context) => Table(
          columnWidths: tv.dataSource.columnWidths,
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
