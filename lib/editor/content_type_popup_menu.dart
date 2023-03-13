import 'package:flutter/material.dart';
import 'package:memex_ui/editor/blocks/bulletpoint_block.dart';
import 'package:memex_ui/editor/blocks/code_block.dart';
import 'package:memex_ui/editor/blocks/editor_block.dart';
import 'package:memex_ui/editor/blocks/math_block.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/blocks/paragraph_block.dart';
import 'package:memex_ui/editor/blocks/quote_block.dart';
import 'package:memex_ui/editor/blocks/heading_block.dart';
import 'package:memex_ui/editor/content_type_popup_state.dart';
import 'package:memex_ui/editor/piece_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:memex_ui/table/table_selection.dart';

class BlockContentType {
  final String name;
  final EditorBlock block;
  const BlockContentType(this.name, this.block);
}

@immutable
class ContentTypePopupMenu extends StatelessWidget {
  static List<BlockContentType> contentTypes = [
    BlockContentType(
      "Heading 1",
      HeadingBlock(1, <Piece>[Piece.sentinel].lockUnsafe),
    ),
    BlockContentType(
      "Heading 2",
      HeadingBlock(2, <Piece>[Piece.sentinel].lockUnsafe),
    ),
    BlockContentType(
      "Heading 3",
      HeadingBlock(3, <Piece>[Piece.sentinel].lockUnsafe),
    ),
    BlockContentType(
      "Math Block",
      MathBlock(<Piece>[Piece.sentinel].lockUnsafe),
    ),
    BlockContentType(
      "Code Block",
      CodeBlock("none", <Piece>[Piece.sentinel].lockUnsafe),
    ),
    BlockContentType(
      "Bulletlist",
      BulletpointBlock(
        <Piece>[Piece.sentinel].lockUnsafe,
        <EditorBlock>[].lockUnsafe,
      ),
    ),
    BlockContentType(
      "Quote Block",
      QuoteBlock(
        <Piece>[Piece.sentinel].lockUnsafe,
      ),
    ),
    BlockContentType(
      "Paragraph Block",
      ParagraphBlock(
        <Piece>[Piece.sentinel].lockUnsafe,
      ),
    ),
  ];

  final Editor editor;

  /// The path of the block on which the popup is shown.
  final BlockPath path;

  late final TableDatasource<BlockContentType> datasource = TableDatasource(
    colDefs: [
      ColumnDefinition(
        label: "Name",
        width: const FlexColumnWidth(),
        cellBuilder: (context, contentType) => SlashPopupEntry(
          path: path,
          editor: editor,
          block: (block) => contentType.block,
          label: contentType.name,
          index: 1,
        ),
      ),
    ],
    getRowCount: () => contentTypes.length,
    getRowValue: (index) => TableValue<BlockContentType>(
      key: ObjectKey(contentTypes[index]),
      value: contentTypes[index],
    ),
  );

  ContentTypePopupMenu({
    super.key,
    required this.editor,
    required this.path,
  });

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: editor.onContentTypeMenuChange.stream,
        builder: (context, snapshot) {
          BlockContentType selectedType =
              contentTypes[editor.state.contentTypePopupState.index];
          datasource.select(
            TableSelection(key: ObjectKey(selectedType), value: selectedType),
          );
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x33000000)),
              color: const Color(0xFFFFFFFF),
              borderRadius: const BorderRadius.all(Radius.circular(2.0)),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0.0, 3.0),
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5.0,
                )
              ],
            ),
            height: 350,
            child: TableView<BlockContentType>(
              rowHeight: 30,
              dataSource: datasource,
              showEvenRowHighlight: false,
            ),
          );
        },
      );
}

class SlashPopupEntry extends StatelessWidget {
  final BlockPath path;
  final Editor editor;
  final EditorBlock Function(EditorBlock) block;
  final String label;
  final int index;

  const SlashPopupEntry({
    super.key,
    required this.path,
    required this.editor,
    required this.block,
    required this.label,
    required this.index,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          editor.commitUndoState();
          editor.state = editor.state
              .replaceBlockAtPath(path, block)
              .copyWithCursor(
                blockPath: path,
                piecePath: PiecePath.fromIterable(const [0]),
                offset: 0,
              )
              .copyWith(
                contentTypePopupState: const ContentTypePopupState.closed(),
              );
          editor.rebuild();
        },
        child: Text(label),
      );
}
