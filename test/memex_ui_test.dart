import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:memex_ui/editor/pieces.dart';
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
        ParagraphBlock(<Piece>[
          const Piece(text: "foo"),
          const Piece(text: "bar"),
          Piece.sentinel,
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
      <Piece>[
        const Piece(text: "f"),
        const Piece(text: "r"),
        Piece.sentinel,
      ].lockUnsafe,
    );
    expect(state.selection.isEmpty, true);
    expect(state.blocks[0].pieces[1].text.length, 1);
    expect(
      state.cursor,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 1,
        offset: 0,
      ),
    );

    // Delete the piece with content "r".
    state = state.moveCursorRightOnce(true);
    expect(
      state.selection.start,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 1,
        offset: 0,
      ),
    );
    expect(
      state.selection.end,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 2,
        offset: 0,
      ),
    );
    state = state.deleteBackwards();
    expect(
      state.blocks[0].pieces,
      <Piece>[
        const Piece(text: "f"),
        Piece.sentinel,
      ].lockUnsafe,
    );
    expect(
      state.cursor,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 1,
        offset: 0,
      ),
    );

    // Move cursor back to the front
    state = state.moveCursorLeftOnce(false);
    expect(
      state.cursor,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 0,
        offset: 0,
      ),
    );

    // Insert a new block
    state = state.append("foo");
    expect(
      state.blocks[0].pieces,
      <Piece>[
        const Piece(text: "foo"),
        const Piece(text: "f"),
        Piece.sentinel,
      ].lockUnsafe,
    );
    // Move back to the start
    state = state.moveCursorLeft(3, false);
    expect(
      state.cursor,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 0,
        offset: 0,
      ),
    );
    // Select "foof"
    state = state.moveCursorRight(4, true);
    expect(
      state.selection.start,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 0,
        offset: 0,
      ),
    );
    expect(
      state.selection.end,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 2,
        offset: 0,
      ),
    );
    // Delete "foof"
    state = state.deleteBackwards();
    expect(
      state.blocks[0].pieces,
      <Piece>[Piece.sentinel].lockUnsafe,
    );
    expect(state.selection.isEmpty, true);
    expect(
      state.cursor,
      Cursor(
        blockPath: BlockPath([0].lockUnsafe),
        pieceIndex: 0,
        offset: 0,
      ),
    );
  });

  test('markdown (de)serialization', () async {
    File markdownFile = File("./test/doc.md");
    EditorState fromMarkdown = await parseMarkdown(markdownFile);
    String toMarkdown = await serializeEditorState(fromMarkdown);
    String originalMarkdown = await markdownFile.readAsString();
    expect(toMarkdown, originalMarkdown);
  });
}
