import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/piece_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import '../cursor.dart';
import './paragraph_block.dart';

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

  /// Calculate this blocks padding based on what blocks border it.
  EdgeInsetsGeometry padding(
    BuildContext context,
    EditorBlock? previousNeighbor,
    EditorBlock? nextNeighbor,
  ) =>
      EdgeInsets.only(
        bottom: MemexTypography.baseFontSize * 1.5,
      );

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
    required Editor editor,
  }) =>
      EditorTextView(
        block: this,
        blockPath: path,
        selection: editor.state.selection,
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
