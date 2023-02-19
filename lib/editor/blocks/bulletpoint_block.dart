import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/selection.dart';
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
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Selection selection,
  }) {
    BoxDecoration? debugBorders;
    if (showDebugFrames && kDebugMode) {
      debugBorders = BoxDecoration(border: Border.all());
    }

    return Container(
      decoration: debugBorders,
      padding: const EdgeInsets.all(5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• "),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditorTextView(
                  block: this,
                  blockPath: path,
                  selection: selection,
                ),
                RenderBlockChildren(
                  children: children,
                  selection: selection,
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
