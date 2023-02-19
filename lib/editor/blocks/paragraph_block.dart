import 'package:flutter/foundation.dart';
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
  Widget build({
    required BuildContext context,
    required BlockPath path,
    required Selection selection,
  }) =>
      EditorTextView(
        block: this,
        blockPath: path,
        selection: selection,
      );
}
