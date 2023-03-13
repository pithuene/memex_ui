import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import './editor_block.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class HeadingBlock extends EditorBlock {
  HeadingBlock.h1(String? initialContent)
      : level = 1,
        super.withInitialContent(initialContent: initialContent);

  HeadingBlock(this.level, super.pieces) : assert(0 < level && level < 4);

  final int level;

  @override
  HeadingBlock copyWith({
    IList<Piece>? pieces,
    int? level,
  }) {
    if (level != null) assert(0 < level && level < 4);
    return HeadingBlock(
      level ?? this.level,
      pieces ?? this.pieces,
    );
  }

  @override
  EdgeInsetsGeometry padding(
    BuildContext context,
    EditorBlock? previousNeighbor,
    EditorBlock? nextNeighbor,
  ) {
    double fontSize = MemexTypography.baseFontSize;
    double topPadding = 0.0;
    if (previousNeighbor is HeadingBlock) {
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
        style: (level == 1)
            ? MemexTypography.heading2
            : (level == 2)
                ? MemexTypography.heading3
                : MemexTypography.heading4,
      );
}
