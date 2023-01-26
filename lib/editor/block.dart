import './cursor.dart';

import 'package:flutter/material.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/rendering.dart';

class EditorBlock {
  EditorBlock({
    String? initialContent,
  }) {
    if (initialContent != null) {
      pieces = pieces.add(TextSpan(text: initialContent));
    }
    pieces = pieces.add(sentinelPiece);
  }

  /// An empty piece at the end of the text.
  /// The cursor is placed here to append text.
  final TextSpan sentinelPiece = const TextSpan(text: "^");

  IList<TextSpan> pieces = <TextSpan>[].lockUnsafe;

  /// Calculate the offset of the cursor in this block.
  /// Returns null if the cursor is not in this block.
  int? getCursorOffset(Cursor cursor) {
    if (cursor.block != this) return null;
    int offset = 0;
    for (int i = 0; i < cursor.pieceIndex; i++) {
      offset += pieces[i].text!.length;
    }
    offset += cursor.offset;
    return offset;
  }
}

class ParagraphBlock extends EditorBlock {
  ParagraphBlock({String? initialContent})
      : super(initialContent: initialContent);
}
