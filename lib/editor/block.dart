import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';

import './cursor.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

/// A block inside an [Editor].
class EditorBlock {
  EditorBlock({
    required this.editor,
    String? initialContent,
  }) {
    if (initialContent != null) {
      pieces = pieces.add(TextSpan(text: initialContent));
    }
    pieces = pieces.add(sentinelPiece);
  }

  /// An empty piece at the end of the text.
  /// The cursor is placed here to append text.
  static const TextSpan sentinelPiece = TextSpan(text: ' ');

  IList<TextSpan> pieces = <TextSpan>[].lockUnsafe;

  /// Reference to the [Editor] of which this block is apart.
  final Editor editor;

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

  /// The function called to create the the widget showing a block.
  /// By default, this just shows the text content,
  /// generally you need to override this function.
  Widget build(BuildContext context) => EditorTextView(
        block: this,
        cursor: editor.cursor,
      );
}

class ParagraphBlock extends EditorBlock {
  ParagraphBlock({
    String? initialContent,
    required Editor editor,
  }) : super(
          initialContent: initialContent,
          editor: editor,
        );

  @override
  Widget build(BuildContext context) => EditorTextView(
        block: this,
        cursor: editor.cursor,
      );
}
