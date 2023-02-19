import 'package:flutter/foundation.dart';
import 'package:memex_ui/editor/blocks/paragraph_block.dart';
import 'package:memex_ui/editor/selection.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import './editor_block.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class EditorBlockWithChildren extends EditorBlock {
  EditorBlockWithChildren.withInitialContent({
    String? initialContent,
    required this.children,
  }) : super.withInitialContent(initialContent: initialContent);

  EditorBlockWithChildren(super.pieces, this.children);

  bool get hasChildren => children.isNotEmpty;
  int get lastChildIndex => children.length - 1;

  IList<EditorBlock> children;

  // TODO: Maybe have a "can contain" list of block types to generally solve the issue of which blocks can contain which? Or is this not a common issue?

  @override
  EditorBlockWithChildren copyWith({
    IList<Piece>? pieces,
    IList<EditorBlock>? children,
  }) =>
      EditorBlockWithChildren(
        pieces ?? this.pieces,
        children ?? this.children,
      );

  EditorBlockWithChildren replaceChildren(
    IList<EditorBlock> Function(IList<EditorBlock>) childrenChange,
  ) =>
      copyWith(children: childrenChange(children));

  @override
  IList<EditorBlock> turnIntoParagraphBlock() =>
      children.insert(0, ParagraphBlock(pieces));

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          super.build(
            context: context,
            path: path,
            selection: selection,
          ),
          Container(height: 5),
          RenderBlockChildren(
            children: children,
            selection: selection,
            parentPath: path,
          ),
        ],
      ),
    );
  }
}

class RenderBlockChildren extends StatelessWidget {
  final IList<EditorBlock> children;
  final Selection selection;
  final BlockPath parentPath;

  const RenderBlockChildren({
    required this.children,
    required this.selection,
    required this.parentPath,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.mapIndexedAndLast((index, child, last) {
          BlockPath childBlockPath = parentPath.add(index);
          return child.build(
            context: context,
            selection: selection,
            path: childBlockPath,
          );
        }).toList(),
      );
}
