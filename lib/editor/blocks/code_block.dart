import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import './editor_block.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class CodeBlock extends EditorBlock {
  String language;
  CodeBlock.withInitialContent({
    String? initialContent,
    required this.language,
  }) : super.withInitialContent(initialContent: initialContent);

  CodeBlock(this.language, super.pieces);

  @override
  EditorBlock copyWith({
    IList<Piece>? pieces,
    String? language,
  }) =>
      CodeBlock(language ?? this.language, pieces ?? this.pieces);

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
      Container(
        color: Colors.black.withAlpha(16),
        padding: const EdgeInsets.all(5),
        child: Stack(children: [
          EditorTextView(
            block: this,
            blockPath: path,
            selection: editor.state.selection,
            style: TextStyle(
              fontFamily: MemexTypography.fontFamilyMonospace,
              color: Colors.black,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: MacosTextField.borderless(
              textAlign: TextAlign.right,
              maxLength: 10,
              controller: TextEditingController(text: language),
              onChanged: (newLanguage) {
                editor.commitUndoState();
                editor.state = editor.state.replaceBlockAtPath(
                  path,
                  (block) => (block as CodeBlock).copyWith(
                    language: newLanguage,
                  ),
                );
                editor.rebuild();
              },
              style: TextStyle(
                fontSize: MemexTypography.baseFontSize * 0.8,
                color: MemexTypography.textColor.withAlpha(100),
              ),
            ),
          ),
        ]),
      );
}
