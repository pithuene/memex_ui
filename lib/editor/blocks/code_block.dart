import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:memex_ui/editor/blocks/bulletpoint_block.dart';
import 'package:memex_ui/editor/blocks/section_block.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import './editor_block.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class CodeBlock extends EditorBlock {
  CodeBlock.withInitialContent({String? initialContent})
      : super.withInitialContent(initialContent: initialContent);

  CodeBlock(super.pieces);

  @override
  EditorBlock copyWith({IList<Piece>? pieces}) =>
      CodeBlock(pieces ?? this.pieces);

  @override
  EdgeInsetsGeometry padding(
    BuildContext context,
    EditorBlock? previousNeighbor,
    EditorBlock? nextNeighbor,
  ) {
    if (nextNeighbor == null) return const EdgeInsets.only(bottom: 0.0);
    double fontSize = MacosTheme.of(context).typography.body.fontSize!;
    return EdgeInsets.only(bottom: fontSize * 0.75);
  }

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required EditorState state,
  }) =>
      Container(
        color: Colors.black.withAlpha(16),
        padding: const EdgeInsets.all(5),
        child: EditorTextView(
          block: this,
          blockPath: path,
          selection: state.selection,
          style: const TextStyle(
            fontFamily: "JetBrainsMono Nerd Font",
            color: Colors.black,
          ),
        ),
      );
}
