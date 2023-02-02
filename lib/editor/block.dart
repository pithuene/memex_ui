import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';

import './cursor.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

/// A block inside an [EditorState].
class EditorBlock {
  EditorBlock.withInitialContent(String? initialContent) {
    if (initialContent != null) {
      assert(initialContent.isNotEmpty);
      pieces = pieces.add(TextSpan(text: initialContent));
    }
    pieces = pieces.add(sentinelPiece);
  }

  EditorBlock(this.pieces);

  /// An empty piece at the end of the text.
  /// The cursor is placed here to append text.
  static const TextSpan sentinelPiece = TextSpan(text: ' ');

  IList<TextSpan> pieces = <TextSpan>[].lockUnsafe;

  /// Calculate the offset of the cursor in this block.
  /// Returns null if the cursor is not in this block.
  int? getCursorOffset(Cursor cursor) {
    int offset = 0;
    for (int i = 0; i < cursor.pieceIndex; i++) {
      offset += pieces[i].text!.length;
    }
    offset += cursor.offset;
    return offset;
  }

  /// The function called to create the the widget showing a block.
  /// By default, this just shows the text content,
  /// generally you need to override this function.
  Widget build(BuildContext context, Cursor? cursor, int depth) =>
      EditorTextView(
        block: this,
        cursor: cursor,
      );

  EditorBlock copyWith({IList<TextSpan>? pieces}) =>
      EditorBlock(pieces ?? this.pieces);
}

class EditorBlockWithChildren extends EditorBlock {
  EditorBlockWithChildren.withInitialContent({
    String? initialContent,
    required this.children,
  }) : super.withInitialContent(initialContent);

  EditorBlockWithChildren(super.pieces, this.children);

  IList<EditorBlock> children;

  @override
  EditorBlockWithChildren copyWith({
    IList<TextSpan>? pieces,
    IList<EditorBlock>? children,
  }) =>
      EditorBlockWithChildren(
        pieces ?? this.pieces,
        children ?? this.children,
      );

  @override
  Widget build(BuildContext context, Cursor? cursor, int depth) => Container(
        decoration: BoxDecoration(border: Border.all()),
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            super.build(
              context,
              (cursor != null && depth == cursor.blockPath.length - 1)
                  ? cursor
                  : null,
              depth,
            ),
            Container(height: 5),
            ...children.mapIndexedAndLast((index, child, last) {
              return child.build(
                context,
                (cursor != null &&
                        cursor.blockPath.length > depth + 1 &&
                        index == cursor.blockPath[depth + 1])
                    ? cursor
                    : null,
                depth + 1,
              );
            }),
          ],
        ),
      );
}

class ParagraphBlock extends EditorBlock {
  ParagraphBlock.withInitialContent({String? initialContent})
      : super.withInitialContent(initialContent);

  ParagraphBlock(super.pieces);

  @override
  EditorBlock copyWith({IList<TextSpan>? pieces}) =>
      ParagraphBlock(pieces ?? this.pieces);

  @override
  Widget build(BuildContext context, Cursor? cursor, int depth) =>
      EditorTextView(
        block: this,
        cursor: cursor,
      );
}

class Heading1Block extends EditorBlockWithChildren {
  Heading1Block.withInitialContent(String? initialContent)
      : super.withInitialContent(
          initialContent: initialContent,
          children: <EditorBlock>[
            ParagraphBlock.withInitialContent(initialContent: "Content")
          ].lockUnsafe,
        );

  Heading1Block(super.pieces, super.children);

  @override
  Heading1Block copyWith({
    IList<TextSpan>? pieces,
    IList<EditorBlock>? children,
  }) =>
      Heading1Block(
        pieces ?? this.pieces,
        children ?? this.children,
      );

  @override
  Widget build(BuildContext context, Cursor? cursor, int depth) => Container(
        decoration: BoxDecoration(border: Border.all()),
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EditorTextView(
              block: this,
              cursor: (cursor != null && depth == cursor.blockPath.length - 1)
                  ? cursor
                  : null,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: "Inter",
              ),
            ),
            Container(height: 5),
            ...children.mapIndexedAndLast((index, child, last) {
              return child.build(
                context,
                (cursor != null &&
                        cursor.blockPath.length > depth + 1 &&
                        index == cursor.blockPath[depth + 1])
                    ? cursor
                    : null,
                depth + 1,
              );
            }),
          ],
        ),
      );
}
