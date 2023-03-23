import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:memex_ui/editor/blocks/bulletpoint_block.dart';
import 'package:memex_ui/editor/blocks/code_block.dart';
import 'package:memex_ui/editor/blocks/heading_block.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/blocks/math_block.dart';
import 'package:memex_ui/editor/content_type_popup_menu.dart';
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

  HeadingBlock turnIntoHeadingBlock(int level) => HeadingBlock(level, pieces);

  BulletpointBlock turnIntoBulletpointBlock() =>
      BulletpointBlock(pieces, <EditorBlock>[].lockUnsafe);

  @override
  EdgeInsetsGeometry padding(
    BuildContext context,
    EditorBlock? previousNeighbor,
    EditorBlock? nextNeighbor,
  ) {
    if (nextNeighbor == null) return const EdgeInsets.only(bottom: 0.0);
    double fontSize = MemexTypography.baseFontSize;
    if (nextNeighbor is BulletpointBlock ||
        nextNeighbor is CodeBlock ||
        nextNeighbor is MathBlock) {
      return EdgeInsets.only(bottom: fontSize * 0.75);
    }
    return EdgeInsets.only(bottom: fontSize * 1.5);
  }

  @override
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Editor editor,
  }) =>
      PortalTarget(
        portalFollower: ContentTypePopupMenu(
          editor: editor,
          path: path,
        ),
        visible: editor.state.contentTypePopupState.isOpen &&
            editor.state.selection.end.blockPath == path,
        anchor: const Aligned(
          follower: Alignment.bottomLeft,
          target: Alignment.topLeft,
          widthFactor: 0.5,
          backup: Aligned(
            follower: Alignment.topLeft,
            target: Alignment.bottomLeft,
            widthFactor: 0.5,
          ),
        ),
        child: EditorTextView(
          block: this,
          blockPath: path,
          editor: editor,
        ),
      );
}
