import 'package:flutter/painting.dart';
import 'package:test/test.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:memex_ui/editor/block.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/cursor.dart';
import 'package:memex_ui/memex_ui.dart';

void main() {
  test('delete across piece boundary', () {
    var state = EditorState(
      blocks: <EditorBlock>[
        ParagraphBlock(<TextSpan>[
          const TextSpan(text: "foo"),
          const TextSpan(text: "bar"),
          EditorBlock.sentinelPiece,
        ].lockUnsafe),
      ].lockUnsafe,
      selection: Selection(
        end: Cursor(
          blockPath: BlockPath([0].lockUnsafe),
          pieceIndex: 0,
          offset: 0,
        ),
      ),
    );
    expect(state.selection.isEmpty, true);
    state = state.moveCursorRightOnce(false);
    state = state.moveCursorRight(4, true);
    expect(
      state.selection.start,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 0,
        offset: 1,
      ),
    );
    expect(
      state.selection.end,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 1,
        offset: 2,
      ),
    );
    state = state.deleteBackwards();
    expect(
      state.blocks[0].pieces,
      <TextSpan>[
        const TextSpan(text: "f"),
        const TextSpan(text: "r"),
        EditorBlock.sentinelPiece,
      ].lockUnsafe,
    );
    expect(state.selection.isEmpty, true);
    expect(state.blocks[0].pieces[1].text!.length, 1);
    expect(
      state.cursor,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 1,
        offset: 0,
      ),
    );
  });
}
