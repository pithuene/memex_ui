import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';

import './cursor.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

/// A block inside an [EditorState].
class EditorBlock {
  EditorBlock.withInitialContent(String? initialContent) {
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
  Widget build(BuildContext context, Cursor? cursor) => EditorTextView(
        block: this,
        cursor: cursor,
      );

  EditorBlock copyWith({
    IList<TextSpan>? pieces,
  }) {
    return EditorBlock(pieces ?? this.pieces);
  }
}

class ParagraphBlock extends EditorBlock {
  ParagraphBlock.withInitialContent({String? initialContent})
      : super.withInitialContent(initialContent);

  ParagraphBlock(super.pieces);

  @override
  Widget build(BuildContext context, Cursor? cursor) => EditorTextView(
        block: this,
        cursor: cursor,
      );
}

class Heading1Block extends EditorBlock {
  Heading1Block(String? initialContent)
      : super.withInitialContent(initialContent);

  @override
  Widget build(BuildContext context, Cursor? cursor) => EditorTextView(
        block: this,
        cursor: cursor,
        style: const TextStyle(
          color: Color(0xFF000000),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: "Inter",
        ),
      );
}
