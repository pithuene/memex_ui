import 'package:flutter/material.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import './editor_block.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class QuoteBlock extends EditorBlock {
  QuoteBlock.withInitialContent({
    String? initialContent,
  }) : super.withInitialContent(initialContent: initialContent);

  QuoteBlock(super.pieces);

  @override
  EditorBlock copyWith({
    IList<Piece>? pieces,
  }) =>
      QuoteBlock(pieces ?? this.pieces);

  @override
  EdgeInsetsGeometry padding(
    BuildContext context,
    EditorBlock? previousNeighbor,
    EditorBlock? nextNeighbor,
  ) {
    if (nextNeighbor == null) return const EdgeInsets.only(bottom: 0.0);
    double fontSize = MemexTypography.baseFontSize;
    return EdgeInsets.only(bottom: fontSize * 0.75);
  }

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Editor editor,
  }) =>
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: MemexTypography.textColor,
              width: MemexTypography.baseFontSize * 0.2,
            ),
            Container(width: MemexTypography.baseFontSize * 0.5),
            Expanded(
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
          ],
        ),
      );
}
