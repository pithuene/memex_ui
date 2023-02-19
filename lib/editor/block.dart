import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/piece_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';

import './cursor.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

/// A block inside an [EditorState].
class EditorBlock {
  EditorBlock.withInitialContent({String? initialContent}) {
    if (initialContent != null) {
      assert(initialContent.isNotEmpty);
      pieces = pieces.add(Piece(text: initialContent));
    }
    pieces = pieces.add(Piece.sentinel);
  }

  EditorBlock(this.pieces);

  IList<Piece> pieces = <Piece>[].lockUnsafe;

  Piece? getPieceFromPath(PiecePath path) {
    if (path.isEmpty) return null;
    Piece? curr = pieces.getOrNull(path[0]);
    for (int i = 1; i < path.length; i++) {
      if (curr == null) return null;
      if (curr is! InlineBlock) return null;
      curr = curr.children.getOrNull(path[i]);
    }
    return curr;
  }

  /// Transform the piece at a given [piecePath]
  /// throguh a [pieceChange] function.
  EditorBlock replacePieceAtPath(
    PiecePath piecePath,
    Piece Function(Piece) pieceChange,
  ) {
    /// Replace a piece at [piecePath] in a tree of [pieces] with a [newPiece].
    IList<Piece> replacePieceInPiecesAtPath(
      IList<Piece> pieces,
      PiecePath piecePath,
      Piece newPiece,
    ) {
      if (piecePath.isTopLevel) {
        return pieces.replace(piecePath[0], newPiece);
      }
      return pieces.replace(
        piecePath[0],
        (pieces[piecePath[0]] as InlineBlock).replaceChildren(
          (children) => replacePieceInPiecesAtPath(
            children,
            piecePath.sublist(1),
            newPiece,
          ),
        ),
      );
    }

    if (piecePath.isTopLevel) {
      return copyWith(
        pieces: pieces.replace(
          piecePath.single,
          pieceChange(getPieceFromPath(piecePath)!),
        ),
      );
    }

    return copyWith(
      pieces: replacePieceInPiecesAtPath(
        pieces,
        piecePath,
        pieceChange(getPieceFromPath(piecePath)!),
      ),
    );
  }

  PiecePath get lastPieceLeaf =>
      PiecePath.fromIterable([pieces.length - 1]).lastLeaf(this);

  /// Remove the piece at a given [piecePath]
  /// **including all its children**.
  EditorBlock removePiece(PiecePath piecePath) {
    if (piecePath.isTopLevel) {
      return copyWith(
        pieces: pieces.removeAt(piecePath.single),
      );
    }

    PiecePath parentPath = piecePath.parent();
    if ((getPieceFromPath(parentPath) as InlineBlock).children.length == 1) {
      // Parent is empty afterwards, delete it.
      return removePiece(parentPath);
    }

    return replacePieceAtPath(
      parentPath,
      (parentPiece) => (parentPiece as InlineBlock)
          .replaceChildren((children) => children.removeAt(piecePath.last)),
    );
  }

  /// Insert a [newPiece] at a given [piecePath].
  EditorBlock insertPieceAtPath(PiecePath piecePath, Piece newPiece) {
    if (piecePath.isTopLevel) {
      return copyWith(pieces: pieces.insert(piecePath.single, newPiece));
    }

    PiecePath parentPath = piecePath.parent();
    return replacePieceAtPath(
      parentPath,
      (parentPiece) => (parentPiece as InlineBlock).replaceChildren(
        (children) => children.insert(
          piecePath.last,
          newPiece,
        ),
      ),
    );
  }

  /// Calculate the offset of the [targetCursor] in this block.
  /// [currentCursor] is the current selection end used to calculate
  /// which blocks are expanded and which aren't.
  int getCursorOffset(
      Cursor targetCursor, bool blockContainsCursor, Cursor currentCursor) {
    int offset = 0;
    for (int i = 0; i < targetCursor.piecePath[0]; i++) {
      offset += pieces[i].getLength(
        blockContainsCursor && currentCursor.piecePath[0] == i,
      );
    }
    Piece topLevelCursorPiece = pieces[targetCursor.piecePath[0]];
    if (topLevelCursorPiece is InlineBlock) {
      for (int i = 0; i < targetCursor.piecePath[1]; i++) {
        offset += topLevelCursorPiece.children[i].getLength(
          blockContainsCursor &&
              currentCursor.piecePath[0] == targetCursor.piecePath[0],
        );
      }
    }
    offset += targetCursor.offset;

    return offset;
  }

  /// Calculate the sum of the text length of all pieces.
  // TODO: Actually use containsCursor not just true
  int getTotalTextLength() => pieces.sumBy((piece) => piece.getLength(true));

  /// The function called to create the the widget showing a block.
  /// By default, this just shows the text content,
  /// generally you need to override this function.
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Selection selection,
  }) =>
      EditorTextView(
        block: this,
        blockPath: path,
        selection: selection,
      );

  EditorBlock copyWith({IList<Piece>? pieces}) =>
      EditorBlock(pieces ?? this.pieces);

  EditorBlock replacePieces(
    IList<Piece> Function(IList<Piece>) piecesChange,
  ) =>
      copyWith(pieces: piecesChange(pieces));

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

  bool get hasChildren => children.isNotEmpty;
  int get lastChildIndex => children.length - 1;

  IList<EditorBlock> children;

  // TODO: Maybe have a "can contain" list of block types to generally solve the issue of which blocks can contain which? Or is this not a common issue?

  @override
  EditorBlockWithChildren copyWith({
    IList<Piece>? pieces,
    IList<EditorBlock>? children,
  }) =>
      EditorBlockWithChildren(
        pieces ?? this.pieces,
        children ?? this.children,
      );

  EditorBlockWithChildren replaceChildren(
    IList<EditorBlock> Function(IList<EditorBlock>) childrenChange,
  ) =>
      copyWith(children: childrenChange(children));

  @override
  IList<EditorBlock> turnIntoParagraphBlock() =>
      children.insert(0, ParagraphBlock(pieces));

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Selection selection,
  }) {
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
            context: context,
            path: path,
            selection: selection,
          ),
          Container(height: 5),
          RenderBlockChildren(
            children: children,
            selection: selection,
            parentPath: path,
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
  EditorBlock copyWith({IList<Piece>? pieces}) =>
      ParagraphBlock(pieces ?? this.pieces);

  SectionBlock turnIntoSectionBlock() => SectionBlock(pieces);

  BulletpointBlock turnIntoBulletpointBlock() =>
      BulletpointBlock(pieces, <EditorBlock>[].lockUnsafe);

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Selection selection,
  }) =>
      EditorTextView(
        block: this,
        blockPath: path,
        selection: selection,
      );
}

class SectionBlock extends EditorBlock {
  SectionBlock.withInitialContent(String? initialContent)
      : super.withInitialContent(initialContent: initialContent);

  SectionBlock(super.pieces);

  @override
  SectionBlock copyWith({IList<Piece>? pieces}) =>
      SectionBlock(pieces ?? this.pieces);

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Selection selection,
  }) =>
      EditorTextView(
        block: this,
        blockPath: path,
        selection: selection,
        style: const TextStyle(
          color: Color(0xFF000000),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: "Inter",
        ),
      );
}

class MathBlock extends EditorBlock {
  MathBlock(super.pieces);

  @override
  MathBlock copyWith({IList<Piece>? pieces}) =>
      MathBlock(pieces ?? this.pieces);

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Selection selection,
  }) {
    final bool isCursorInThisBlock = selection.end.blockPath == path;
    String tex = TextSpan(
      children: pieces
          .map(
            (piece) => piece.toSpan(true),
          )
          .toList(),
    ).toPlainText();
    if (isCursorInThisBlock) {
      return Row(
        children: [
          ColoredBox(
            color: const Color(0x20000000),
            child: EditorTextView(
              block: this,
              blockPath: path,
              selection: selection,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontFamily: "monospace",
              ),
            ),
          ),
          Container(width: 30),
          Math.tex(
            tex,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
            mathStyle: MathStyle.display,
          ),
        ],
      );
    } else {
      return Center(
        child: Math.tex(
          tex,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
          mathStyle: MathStyle.display,
        ),
      );
    }
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
    IList<Piece>? pieces,
    IList<EditorBlock>? children,
  }) =>
      BulletpointBlock(
        pieces ?? this.pieces,
        children ?? this.children,
      );

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Selection selection,
  }) {
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
                  blockPath: path,
                  selection: selection,
                ),
                RenderBlockChildren(
                  children: children,
                  selection: selection,
                  parentPath: path,
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
  final Selection selection;
  final BlockPath parentPath;

  const RenderBlockChildren({
    required this.children,
    required this.selection,
    required this.parentPath,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.mapIndexedAndLast((index, child, last) {
          BlockPath childBlockPath = parentPath.add(index);
          return child.build(
            context: context,
            selection: selection,
            path: childBlockPath,
          );
        }).toList(),
      );
}
