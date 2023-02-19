import 'package:flutter_math_fork/flutter_math.dart';
import 'package:memex_ui/editor/selection.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
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
    required Selection selection,
  }) {
    final bool isCursorInThisBlock = selection.end.blockPath == path;
    String tex = TextSpan(
      children: pieces
          .map(
            (piece) => piece.toSpan(true),
          )
          .toList(),
    ).toPlainText();
    if (isCursorInThisBlock) {
      return Row(
        children: [
          ColoredBox(
            color: const Color(0x20000000),
            child: EditorTextView(
              block: this,
              blockPath: path,
              selection: selection,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontFamily: "monospace",
              ),
            ),
          ),
          Container(width: 30),
          Math.tex(
            tex,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
            mathStyle: MathStyle.display,
          ),
        ],
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
