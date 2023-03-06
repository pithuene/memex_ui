import 'package:macos_ui/macos_ui.dart';
import 'package:memex_ui/editor/blocks/bulletpoint_block.dart';
import 'package:memex_ui/editor/blocks/section_block.dart';
import 'package:memex_ui/editor/selection.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import './editor_block.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class ParagraphBlock extends EditorBlock {
  ParagraphBlock.withInitialContent({String? initialContent})
      : super.withInitialContent(initialContent: initialContent);

  ParagraphBlock(super.pieces);

  @override
  EditorBlock copyWith({IList<Piece>? pieces}) =>
      ParagraphBlock(pieces ?? this.pieces);

  SectionBlock turnIntoSectionBlock() => SectionBlock(pieces);

  BulletpointBlock turnIntoBulletpointBlock() =>
      BulletpointBlock(pieces, <EditorBlock>[].lockUnsafe);

  @override
  EdgeInsetsGeometry padding(
    BuildContext context,
    EditorBlock? previousNeighbor,
    EditorBlock? nextNeighbor,
  ) {
    if (nextNeighbor == null) return const EdgeInsets.only(bottom: 0.0);
    double fontSize = MacosTheme.of(context).typography.body.fontSize!;
    if (nextNeighbor is BulletpointBlock) {
      return EdgeInsets.only(bottom: fontSize * 0.75);
    }
    return EdgeInsets.only(bottom: fontSize * 1.5);
  }

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required EditorState state,
  }) =>
      EditorTextView(
        block: this,
        blockPath: path,
        selection: state.selection,
      );
}
