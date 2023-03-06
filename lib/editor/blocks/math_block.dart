import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import './editor_block.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class MathBlock extends EditorBlock {
  MathBlock(super.pieces);

  @override
  MathBlock copyWith({IList<Piece>? pieces}) =>
      MathBlock(pieces ?? this.pieces);

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Editor editor,
  }) {
    final bool isCursorInThisBlock =
        editor.state.selection.end.blockPath == path;
    String tex = TextSpan(
      children: pieces
          .map(
            (piece) => piece.toSpan(true),
          )
          .toList(),
    ).toPlainText();
    if (isCursorInThisBlock) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                color: Colors.black.withAlpha(16),
                padding: const EdgeInsets.all(5),
                child: EditorTextView(
                  block: this,
                  blockPath: path,
                  selection: editor.state.selection,
                  style: TextStyle(
                    fontFamily: MemexTypography.fontFamilyMonospace,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Container(width: 30),
            Expanded(
              child: Center(
                child: Math.tex(
                  tex,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                  mathStyle: MathStyle.display,
                ),
              ),
            ),
          ],
        ),
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
