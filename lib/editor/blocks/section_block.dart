import 'package:flutter/foundation.dart';
import 'package:memex_ui/editor/selection.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/text_view.dart';
import 'package:memex_ui/memex_ui.dart';
import './editor_block.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class SectionBlock extends EditorBlock {
  SectionBlock.withInitialContent(String? initialContent)
      : super.withInitialContent(initialContent: initialContent);

  SectionBlock(super.pieces);

  @override
  SectionBlock copyWith({IList<Piece>? pieces}) =>
      SectionBlock(pieces ?? this.pieces);

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
        style: const TextStyle(
          color: Color(0xFF000000),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: "Inter",
        ),
      );
}
