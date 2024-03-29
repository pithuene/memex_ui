import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/blocks/heading_block.dart';
import 'package:memex_ui/editor/piece_path.dart';
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
  EdgeInsetsGeometry padding(
    BuildContext context,
    EditorBlock? previousNeighbor,
    EditorBlock? nextNeighbor,
  ) =>
      EdgeInsets.only(
        bottom: nextNeighbor is HeadingBlock
            ? MemexTypography.baseFontSize * 1.5
            : MemexTypography.baseFontSize * 0.25,
      );

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
            (piece) => piece.toSpan(editor, true),
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
                padding: const EdgeInsets.all(10),
                child: EditorTextView(
                  block: this,
                  blockPath: path,
                  editor: editor,
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
      return HoverDetector(
        builder: (context, isHovered, child) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  editor.state = editor.state.copyWithCursor(
                    blockPath: path,
                    piecePath: PiecePath.fromIterable(const [0]),
                    offset: 0,
                  );
                  editor.rebuild();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(3.0)),
                    color: isHovered
                        ? Colors.black.withAlpha(16)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
            child!,
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          child: Math.tex(
            tex,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
            mathStyle: MathStyle.display,
          ),
        ),
      );
    }
  }
}
