import 'package:macos_ui/macos_ui.dart';
import 'package:memex_ui/memex_ui.dart';

class TableHeader<T> extends StatelessWidget {
  const TableHeader({
    super.key,
    required this.order,
    this.columnHeaderClicked,
  });

  static const double horizontalPadding = 10;

  final Function(ColumnDefinition<T>)? columnHeaderClicked;

  final TableOrder<T>? order;

  @override
  Widget build(BuildContext context) {
    final tv = TableView.of<T>(context);
    return Table(
      columnWidths: [
        const FixedColumnWidth(horizontalPadding),
        ...tv.dataSource.colDefs.map((colDef) => colDef.width),
        const FixedColumnWidth(horizontalPadding),
      ].asMap(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            ...tv.dataSource.colDefs.mapIndexedAndLast((index, colDef, _) {
              final bool isOrderedByThisColumn =
                  colDef.label == order?.column.label;

              final TextStyle labelStyle = isOrderedByThisColumn
                  ? MacosTheme.of(context)
                      .typography
                      .headline
                      .copyWith(fontWeight: FontWeight.w600)
                  : MacosTheme.of(context).typography.headline;

              final Widget orderDirectionArrow = isOrderedByThisColumn
                  ? CustomPaint(
                      size: const Size.square(16),
                      painter: _SortDirectionCaretPainter(
                        color: MemexColor.grid,
                        up: order?.direction == TableOrderDirection.ascending,
                      ),
                    )
                  : const SizedBox.shrink();

              return GestureDetector(
                onTap: () {
                  if (columnHeaderClicked != null) {
                    columnHeaderClicked!(colDef);
                  }
                },
                child: [
                  const Spacer(),
                  Text(colDef.label, style: labelStyle),
                  const Spacer(),
                  orderDirectionArrow,
                ]
                    .toRow()
                    .padding(horizontal: 10, vertical: 3)
                    .border(
                      right: 1.0,
                      color: (index == tv.dataSource.colDefs.length - 1)
                          ? MemexColor.transparent
                          : MemexColor.grid,
                    )
                    .padding(vertical: 5),
              );
            }),
            const SizedBox.shrink(),
          ],
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 1,
                color: MemexColor.grid,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SortDirectionCaretPainter extends CustomPainter {
  const _SortDirectionCaretPainter({
    required this.color,
    required this.up,
  });

  final Color color;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final hPadding = size.height / 3;

    /// Draw carets
    if (!up) {
      final p1 = Offset(hPadding, size.height / 2 - 1.0);
      final p2 = Offset(size.width / 2, size.height / 2 + 2.0);
      final p3 = Offset(size.width / 2 + 1.0, size.height / 2 + 1.0);
      final p4 = Offset(size.width - hPadding, size.height / 2 - 1.0);
      final paint = Paint()
        ..color = color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.75;
      canvas.drawLine(p1, p2, paint);
      canvas.drawLine(p3, p4, paint);
    } else {
      final p1 = Offset(hPadding, size.height / 2 + 1.0);
      final p2 = Offset(size.width / 2, size.height / 2 - 2.0);
      final p3 = Offset(size.width / 2 + 1.0, size.height / 2 - 1.0);
      final p4 = Offset(size.width - hPadding, size.height / 2 + 1.0);
      final paint = Paint()
        ..color = color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.75;
      canvas.drawLine(p1, p2, paint);
      canvas.drawLine(p3, p4, paint);
    }
  }

  @override
  bool shouldRepaint(_SortDirectionCaretPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(_SortDirectionCaretPainter oldDelegate) => false;
}
