import 'package:flutter/foundation.dart';
import 'package:memex_ui/editor/blocks/paragraph_block.dart';
import 'package:macos_ui/macos_ui.dart';
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
    required EditorState state,
  }) {
    BoxDecoration? debugBorders;
    if (showDebugFrames && kDebugMode) {
      debugBorders = BoxDecoration(border: Border.all());
    }

    double fontSize = MacosTheme.of(context).typography.body.fontSize!;
    return Container(
      decoration: debugBorders,
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          super.build(
            context: context,
            path: path,
            state: state,
          ),
          Container(height: fontSize),
          RenderBlockChildren(
            children: children,
            state: state,
            parentPath: path,
          ),
        ],
      ),
    );
  }
}

class PaddedBlock extends StatelessWidget {
  /// This block.
  final EditorBlock block;

  /// Path to this block.
  final BlockPath path;

  /// The current [EditorState].
  final EditorState state;

  const PaddedBlock({
    super.key,
    required this.block,
    required this.state,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    EditorBlock? previousBlock =
        state.getBlockFromPath(path.previousNeighbor());
    EditorBlock? nextBlock = state.getBlockFromPath(path.nextNeighbor());
    return Padding(
      padding: block.padding(context, previousBlock, nextBlock),
      child: block.build(
        context: context,
        state: state,
        path: path,
      ),
    );
  }
}

class RenderBlockChildren extends StatelessWidget {
  final IList<EditorBlock> children;
  final EditorState state;
  final BlockPath parentPath;

  const RenderBlockChildren({
    required this.children,
    required this.state,
    required this.parentPath,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.mapIndexedAndLast((index, child, last) {
          BlockPath childBlockPath = parentPath.add(index);
          return PaddedBlock(
            block: child,
            state: state,
            path: childBlockPath,
          );
        }).toList(),
      );
}
