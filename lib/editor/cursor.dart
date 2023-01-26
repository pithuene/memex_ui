import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart';

@immutable
class Cursor {
  const Cursor({
    required this.block,
    required this.pieceIndex,
    required this.offset,
  });

  final EditorBlock block;
  final int pieceIndex;
  final int offset;

  /// Move the cursor right by one character.
  Cursor moveRightOnce(IList<TextSpan> pieces) {
    TextSpan currPiece = pieces[pieceIndex];
    if (offset < currPiece.text!.length - 1) {
      // Not at the end yet, offset can be incremented.
      return copyWith(offset: offset + 1);
    } else {
      // At the end of a piece, must jump.
      if (pieceIndex < pieces.length - 1) {
        // Not yet on the last piece.
        return copyWith(
          pieceIndex: pieceIndex + 1,
          offset: 0,
        );
      } else {
        return this;
        // TODO: This is where you should probably jump to the next block.
      }
    }
  }

  /// Move the cursor left by one character.
  Cursor moveLeftOnce(IList<TextSpan> pieces) {
    TextSpan currPiece = pieces[pieceIndex];
    if (offset > 0) {
      // Not at the beginning yet, offset can be decremented.
      return copyWith(offset: offset - 1);
    } else {
      // At the beginning of a piece, must jump.
      if (pieceIndex > 0) {
        // Not yet on the first piece.
        return copyWith(
          pieceIndex: pieceIndex - 1,
          offset: pieces[pieceIndex - 1].text!.length - 1,
        );
      } else {
        return this;
        // TODO: This is where you should probably jump to the previous block.
      }
    }
  }

  /// Move the cursor right by a given distance.
  /// To move by one character use [moveRightOnce].
  Cursor moveRight(int distance, IList<TextSpan> pieces) {
    Cursor curr = this;
    for (int i = 0; i < distance; i++) {
      curr = curr.moveRightOnce(pieces);
    }
    return curr;
  }

  /// Move the cursor left by a given distance.
  /// To move by one character use [moveLeftOnce].
  Cursor moveLeft(int distance, IList<TextSpan> pieces) {
    Cursor curr = this;
    for (int i = 0; i < distance; i++) {
      curr = curr.moveLeftOnce(pieces);
    }
    return curr;
  }

  Cursor copyWith({
    EditorBlock? block,
    int? pieceIndex,
    int? offset,
  }) {
    return Cursor(
      block: block ?? this.block,
      pieceIndex: pieceIndex ?? this.pieceIndex,
      offset: offset ?? this.offset,
    );
  }
}
