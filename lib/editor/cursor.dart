import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/blocks/editor_block.dart';
import 'package:memex_ui/editor/editor_state.dart';
import 'package:memex_ui/editor/piece_path.dart';
import 'package:memex_ui/memex_ui.dart';

@immutable
class Cursor {
  const Cursor({
    required this.blockPath,
    required this.piecePath,
    required this.offset,
  });

  /// A list of indices specifying the cursor block.
  final BlockPath blockPath;
  final PiecePath piecePath;
  final int offset;

  /// Whether the cursor is on the last character of the current piece.
  bool isAtPieceEnd(EditorState editorState) =>
      offset == editorState.getCursorPiece(this).text.length - 1;

  /// Whether the cursor is on the first character of the current piece.
  bool get isAtPieceStart => offset == 0;

  /// Whether the cursor is on the last piece of its block.
  bool isOnLastPiece(EditorState state) {
    EditorBlock cursorBlock = state.getCursorBlock(this);
    return piecePath.isLast(cursorBlock);
  }

  bool get isOnFirstPiece {
    for (int i = 0; i < piecePath.length; i++) {
      if (piecePath[i] != 0) return false;
    }
    return true;
  }

  /// Whether the position of this cursor points to a place before the [other] cursor.
  bool isBefore(Cursor other) {
    int blockComparisonResult = blockPath.compareTo(other.blockPath);
    if (blockComparisonResult < 0) {
      return true;
    } else if (blockComparisonResult > 0) {
      return false;
    } else {
      int pieceComparisonResult = piecePath.compareTo(other.piecePath);
      if (pieceComparisonResult < 0) {
        return true;
      } else if (pieceComparisonResult > 0) {
        return false;
      } else {
        return offset < other.offset;
      }
    }
  }

  Cursor copyWith({
    BlockPath? blockPath,
    PiecePath? piecePath,
    int? offset,
  }) {
    return Cursor(
      blockPath: blockPath ?? this.blockPath,
      piecePath: piecePath ?? this.piecePath,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) => (other is Cursor)
      ? (other.blockPath == blockPath &&
          other.piecePath == piecePath &&
          other.offset == offset)
      : false;

  @override
  String toString() => "block: $blockPath, piece: $piecePath, offset: $offset)";

  Cursor moveLeftOnce(EditorState state) {
    if (!isAtPieceStart) {
      return copyWith(offset: offset - 1);
    }
    // At the beginning of a piece, must jump.

    if (!isOnFirstPiece) {
      return copyWith(
        piecePath: piecePath.previous(state.getCursorBlock(this)),
        offset: state.getCursorPreviousPiece(this).text.length - 1,
      );
    }
    // On the first piece, must jump to the previous block.

    BlockPath? previousBlockPath = blockPath.previous(state);
    if (previousBlockPath == null) {
      // Can't move, this is the first block.
      return this;
    }
    // There is another block to jump to.

    EditorBlock previousBlock = state.getBlockFromPath(previousBlockPath)!;
    return copyWith(
      blockPath: previousBlockPath,
      piecePath: previousBlock.lastPieceLeaf,
      offset: previousBlock
              .getPieceFromPath(previousBlock.lastPieceLeaf)!
              .text
              .length -
          1,
    );
  }

  Cursor moveRightOnce(EditorState state) {
    if (!isAtPieceEnd(state)) {
      return copyWith(offset: offset + 1);
    }
    // At the end of a piece, must jump.
    if (!isOnLastPiece(state)) {
      return copyWith(
        piecePath: piecePath.next(state.getCursorBlock(state.cursor)),
        offset: 0,
      );
    }
    // On the last piece, must jump to next block.
    BlockPath? nextBlockPath = blockPath.next(state);
    if (nextBlockPath == null) {
      // Can't move, this is the last block.
      return this;
    }
    // There is another block to jump to.
    return copyWith(
      blockPath: nextBlockPath,
      piecePath: PiecePath.fromIterable(const [0])
          .firstLeaf(state.getBlockFromPath(nextBlockPath)!),
      offset: 0,
    );
  }
}
