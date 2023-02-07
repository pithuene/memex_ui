import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';

import './cursor.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

/// A block inside an [EditorState].
class EditorBlock {
  EditorBlock.withInitialContent({String? initialContent}) {
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

  /// Turn this block into a [ParagraphBlock].
  /// Returns a list of [EditorBlock]s to replace it.
  /// If the block has no children, the result list should simply contain a single [ParagraphBlock].
  /// If the block does have children, the result shoud start with a [ParagraphBlock] and somehow unwrap the children afterwards.
  IList<EditorBlock> turnIntoParagraphBlock() =>
      <EditorBlock>[ParagraphBlock(pieces)].lockUnsafe;
}

class EditorBlockWithChildren extends EditorBlock {
  EditorBlockWithChildren.withInitialContent({
    String? initialContent,
    required this.children,
  }) : super.withInitialContent(initialContent: initialContent);

  EditorBlockWithChildren(super.pieces, this.children);

  IList<EditorBlock> children;

  // TODO: Maybe have a "can contain" list of block types to generally solve the issue of which blocks can contain which? Or is this not a common issue?

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
  IList<EditorBlock> turnIntoParagraphBlock() =>
      children.insert(0, ParagraphBlock(pieces));

  @override
  Widget build(BuildContext context, Cursor? cursor, int depth) {
    BoxDecoration? debugBorders;
    if (showDebugFrames && kDebugMode) {
      debugBorders = BoxDecoration(border: Border.all());
    }

    return Container(
      decoration: debugBorders,
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
          RenderBlockChildren(
            children: children,
            cursor: cursor,
            depth: depth,
          ),
        ],
      ),
    );
  }
}

class ParagraphBlock extends EditorBlock {
  ParagraphBlock.withInitialContent({String? initialContent})
      : super.withInitialContent(initialContent: initialContent);

  ParagraphBlock(super.pieces);

  @override
  EditorBlock copyWith({IList<TextSpan>? pieces}) =>
      ParagraphBlock(pieces ?? this.pieces);

  SectionBlock turnIntoSectionBlock() => SectionBlock(pieces);

  BulletpointBlock turnIntoBulletpointBlock() =>
      BulletpointBlock(pieces, <EditorBlock>[].lockUnsafe);

  @override
  Widget build(BuildContext context, Cursor? cursor, int depth) =>
      EditorTextView(
        block: this,
        cursor: cursor,
      );
}

class SectionBlock extends EditorBlock {
  SectionBlock.withInitialContent(String? initialContent)
      : super.withInitialContent(initialContent: initialContent);

  SectionBlock(super.pieces);

  @override
  SectionBlock copyWith({IList<TextSpan>? pieces}) =>
      SectionBlock(pieces ?? this.pieces);

  @override
  Widget build(BuildContext context, Cursor? cursor, int depth) {
    return EditorTextView(
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
    );
  }
}

class BulletpointBlock extends EditorBlockWithChildren {
  BulletpointBlock.withInitialContent(String? initialContent)
      : super.withInitialContent(
          initialContent: initialContent,
          children: <EditorBlock>[].lockUnsafe,
        );

  BulletpointBlock(super.pieces, super.children);

  @override
  BulletpointBlock copyWith({
    IList<TextSpan>? pieces,
    IList<EditorBlock>? children,
  }) =>
      BulletpointBlock(
        pieces ?? this.pieces,
        children ?? this.children,
      );

  @override
  Widget build(BuildContext context, Cursor? cursor, int depth) {
    BoxDecoration? debugBorders;
    if (showDebugFrames && kDebugMode) {
      debugBorders = BoxDecoration(border: Border.all());
    }

    return Container(
      decoration: debugBorders,
      padding: const EdgeInsets.all(5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• "),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditorTextView(
                  block: this,
                  cursor:
                      (cursor != null && depth == cursor.blockPath.length - 1)
                          ? cursor
                          : null,
                ),
                RenderBlockChildren(
                  children: children,
                  cursor: cursor,
                  depth: depth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RenderBlockChildren extends StatelessWidget {
  final IList<EditorBlock> children;
  final Cursor? cursor;
  final int depth;

  const RenderBlockChildren({
    required this.children,
    required this.cursor,
    required this.depth,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.mapIndexedAndLast((index, child, last) {
          return child.build(
            context,
            (cursor != null &&
                    cursor!.blockPath.length > depth + 1 &&
                    index == cursor!.blockPath[depth + 1])
                ? cursor
                : null,
            depth + 1,
          );
        }).toList(),
      );
}
