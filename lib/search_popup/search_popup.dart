import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/overlay.dart';

Future<T?> openSearchPopup<T>(
  BuildContext context,
  Future<List<T>> Function(String?) searchCallback,
  Widget Function(BuildContext, T) builder,
) async {
  var completer = Completer<T?>();

  openOverlay(
    context,
    (context, entry) => SearchPopup<T>(
      overlayEntry: entry,
      onSelect: (result) {
        completer.complete(result);
      },
      searchCallback: searchCallback,
      builder: builder,
    ),
  );

  return completer.future;
}

class SearchPopup<T> extends StatefulWidget {
  final OverlayEntry overlayEntry;
  final void Function(T?) onSelect;

  /// Given a search query, return a list of results.
  final Future<List<T>> Function(String?) searchCallback;

  final Widget Function(BuildContext, T) builder;

  const SearchPopup({
    super.key,
    required this.overlayEntry,
    required this.onSelect,
    required this.searchCallback,
    required this.builder,
  });

  @override
  State<StatefulWidget> createState() => _SearchPopupState<T>();
}

class _SearchPopupState<T> extends State<SearchPopup<T>> {
  FocusNode wrapperFocusNode = FocusNode();
  FocusNode editableTextFocusNode = FocusNode();
  TextEditingController searchFieldController = TextEditingController();

  List<T> results = [];

  late final TableDatasource<T> resultDatasource = TableDatasource<T>(
    colDefs: [
      ColumnDefinition(
        label: "Filename",
        width: const FlexColumnWidth(),
        cellBuilder: widget.builder,
      )
    ],
    getRowCount: () => results.length,
    getRowValue: (index) => TableValue<T>(
      key: ValueKey(index),
      value: results[index],
    ),
  );

  @override
  void initState() {
    super.initState();
    editableTextFocusNode.requestFocus();
  }

  void close(T? result) {
    widget.onSelect(result);
    widget.overlayEntry.remove();
  }

  void search(String? query) async {
    results = await widget.searchCallback(query);
    resultDatasource.dataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: wrapperFocusNode,
      onKey: (event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          resultDatasource.moveSelectionDown();
        } else if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowUp) {
          resultDatasource.moveSelectionUp();
        } else if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          close(null);
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(3.0)),
        ),
        width: 1000,
        height: 700,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 6.0,
                left: 10.0,
                right: 6.0,
              ),
              child: Row(
                children: [
                  MemexIcon(
                    CupertinoIcons.search,
                    size: MemexTypography.heading2.fontSize,
                  ),
                  Container(width: 10),
                  Expanded(
                    child: EditableText(
                      controller: searchFieldController,
                      focusNode: editableTextFocusNode,
                      style: MemexTypography.heading2
                          .copyWith(fontWeight: FontWeight.normal),
                      cursorColor: MemexColor.text,
                      backgroundCursorColor: MemexColor.white,
                      selectionColor: MemexColor.textSelection,
                      onChanged: search,
                      onSubmitted: (String? result) {
                        close(resultDatasource.selectedRows.single);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: TableView(
                rowHeight: 30,
                dataSource: resultDatasource,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
