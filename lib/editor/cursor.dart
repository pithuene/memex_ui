import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart';

import './block.dart';

@immutable
class Cursor {
  const Cursor({
    required this.blockIndex,
    required this.pieceIndex,
    required this.offset,
  });

  final int blockIndex;
  final int pieceIndex;
  final int offset;

  /*
  /// The piece in which the cursor is located.
  TextSpan get piece => block.pieces[pieceIndex];

  /// The piece before the one the cursor is on.
  TextSpan? get previousPiece =>
      pieceIndex > 0 ? block.pieces[pieceIndex - 1] : null;

  /// The piece after the one the cursor is on.
  TextSpan? get nextPiece => pieceIndex < block.pieces.length - 1
      ? block.pieces[pieceIndex + 1]
      : null;
  */

  /// Whether the cursor is on the last character of the current piece.
  bool isAtPieceEnd(EditorState editorState) =>
      offset == editorState.getCursorPiece(this).text!.length - 1;

  /// Whether the cursor is on the first character of the current piece.
  bool get isAtPieceStart => offset == 0;

  Cursor copyWith({
    int? blockIndex,
    int? pieceIndex,
    int? offset,
  }) {
    return Cursor(
      blockIndex: blockIndex ?? this.blockIndex,
      pieceIndex: pieceIndex ?? this.pieceIndex,
      offset: offset ?? this.offset,
    );
  }
}
