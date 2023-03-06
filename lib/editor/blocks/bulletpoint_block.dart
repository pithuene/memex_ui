import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/blocks/paragraph_block.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import './editor_block.dart';
import './editor_block_with_children.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class BulletpointBlock extends EditorBlockWithChildren {
  BulletpointBlock.withInitialContent(String? initialContent)
      : super.withInitialContent(
          initialContent: initialContent,
          children: <EditorBlock>[].lockUnsafe,
        );

  BulletpointBlock(super.pieces, super.children);

  @override
  BulletpointBlock copyWith({
    IList<Piece>? pieces,
    IList<EditorBlock>? children,
  }) =>
      BulletpointBlock(
        pieces ?? this.pieces,
        children ?? this.children,
      );

  @override
  EdgeInsetsGeometry padding(
    BuildContext context,
    EditorBlock? previousNeighbor,
    EditorBlock? nextNeighbor,
  ) {
    if (nextNeighbor == null) return const EdgeInsets.only(bottom: 0);
    double fontSize = MemexTypography.baseFontSize;
    if (nextNeighbor is BulletpointBlock) {
      return EdgeInsets.only(bottom: fontSize * 0.5);
    }
    if (nextNeighbor is ParagraphBlock) {
      return EdgeInsets.only(bottom: fontSize * 0.5);
    }
    return EdgeInsets.only(bottom: fontSize * 1.5);
  }

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Editor editor,
  }) {
    BoxDecoration? debugBorders;
    if (showDebugFrames && kDebugMode) {
      debugBorders = BoxDecoration(border: Border.all());
    }

    double fontSize = MemexTypography.baseFontSize;
    return Container(
      decoration: debugBorders,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.normal,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditorTextView(
                  block: this,
                  blockPath: path,
                  selection: editor.state.selection,
                ),
                Container(height: (children.isEmpty) ? 0.0 : fontSize * 0.5),
                RenderBlockChildren(
                  children: children,
                  editor: editor,
                  parentPath: path,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
