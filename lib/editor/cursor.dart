import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
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
  final IList<int> blockPath;
  final int pieceIndex;
  final int offset;

  /// Whether the cursor is on the last character of the current piece.
  bool isAtPieceEnd(EditorState editorState) =>
      offset == editorState.getCursorPiece(this).text!.length - 1;

  /// Whether the cursor is on the first character of the current piece.
  bool get isAtPieceStart => offset == 0;

  /// Get the block path of the next neighbor of the cursor block.
  /// There is no guarantee that this neighbor exists.
  IList<int> nextNeighborBlock() => blockPath.replace(
        blockPath.length - 1,
        blockPath.last + 1,
      );

  IList<int> previousNeighborBlock() => blockPath.replace(
        blockPath.length - 1,
        blockPath.last - 1,
      );

  Cursor copyWith({
    IList<int>? blockPath,
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
