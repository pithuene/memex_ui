import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import './editor_block.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class SectionBlock extends EditorBlock {
  SectionBlock.withInitialContent(String? initialContent)
      : super.withInitialContent(initialContent: initialContent);

  SectionBlock(super.pieces);

  @override
  SectionBlock copyWith({IList<Piece>? pieces}) =>
      SectionBlock(pieces ?? this.pieces);

  @override
  EdgeInsetsGeometry padding(
    BuildContext context,
    EditorBlock? previousNeighbor,
    EditorBlock? nextNeighbor,
  ) {
    double fontSize = MemexTypography.baseFontSize;
    double topPadding = 0.0;
    if (previousNeighbor is SectionBlock) {
      topPadding = fontSize * 1.5;
    }
    return EdgeInsets.only(
      bottom: fontSize * 0.75,
      top: topPadding,
    );
  }

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Editor editor,
  }) =>
      EditorTextView(
        block: this,
        blockPath: path,
        editor: editor,
        style: MemexTypography.heading2,
      );
}
