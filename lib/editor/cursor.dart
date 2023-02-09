import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/editor_state.dart';
import 'package:memex_ui/memex_ui.dart';

@immutable
class Cursor {
  const Cursor({
    required this.blockPath,
    required this.pieceIndex,
    required this.offset,
  });

  /// A list of indices specifying the cursor block.
  final BlockPath blockPath;
  final int pieceIndex;
  final int offset;

  /// Whether the cursor is on the last character of the current piece.
  bool isAtPieceEnd(EditorState editorState) =>
      offset == editorState.getCursorPiece(this).text!.length - 1;

  /// Whether the cursor is on the first character of the current piece.
  bool get isAtPieceStart => offset == 0;

  /// Whether the cursor is on the last piece of its block.
  bool isOnLastPiece(EditorState state) =>
      pieceIndex == state.getCursorBlock(this).pieces.length - 1;

  bool get isOnFirstPiece => pieceIndex == 0;

  /// Whether the position of this cursor points to a place before the [other] cursor.
  bool isBefore(Cursor other) {
    int blockComparisonResult = blockPath.compareTo(other.blockPath);
    if (blockComparisonResult < 0) {
      return true;
    } else if (blockComparisonResult > 0) {
      return false;
    } else {
      if (pieceIndex != other.pieceIndex) return pieceIndex < other.pieceIndex;
      return offset < other.offset;
    }
  }

  Cursor copyWith({
    BlockPath? blockPath,
    int? pieceIndex,
    int? offset,
  }) {
    return Cursor(
      blockPath: blockPath ?? this.blockPath,
      pieceIndex: pieceIndex ?? this.pieceIndex,
      offset: offset ?? this.offset,
    );
  }
}
