import 'dart:async';

import './cursor.dart';
import './block.dart';

import 'package:flutter/material.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class Editor {
  EditorState state;
  Editor(this.state);

  /// Emits every time the cursor or selection changes.
  /// Used for rebuilding.
  StreamController<void> onCursorChange = StreamController.broadcast();

  // No new state
  void moveCursorRightOnce() => state = state.moveCursorRightOnce();
  void moveCursorLeftOnce() => state = state.moveCursorLeftOnce();

  // New state // TODO: Undo / Redo
  void append(String content) => state = state.append(content);
  void deleteBackwards() => state = state.deleteBackwards();
  void newLine() => state = state.newLine(); // TODO: Name newBlock?
}

class EditorState {
  /// The top level blocks of the editor.
  late final IList<EditorBlock> blocks;
  late final Cursor cursor;

  EditorState.withInitialContent(String? initialContent) {
    blocks = <EditorBlock>[
      ParagraphBlock.withInitialContent(initialContent: initialContent),
      ParagraphBlock.withInitialContent(initialContent: "Ein neuer Absatz."),
    ].lockUnsafe;
    cursor = const Cursor(
      blockIndex: 0,
      pieceIndex: 0,
      offset: 0,
    );
  }

  EditorState({
    required this.blocks,
    required this.cursor,
  });

  EditorState copyWith({
    IList<EditorBlock>? blocks,
    Cursor? cursor,
  }) {
    return EditorState(
      blocks: blocks ?? this.blocks,
      cursor: cursor ?? this.cursor,
    );
  }

  EditorBlock getCursorBlock(Cursor cursor) => blocks[cursor.blockIndex];

  TextSpan getCursorPiece(Cursor cursor) =>
      blocks[cursor.blockIndex].pieces[cursor.pieceIndex];

  TextSpan getCursorPreviousPiece(Cursor cursor) =>
      blocks[cursor.blockIndex].pieces[cursor.pieceIndex - 1];

  TextSpan getCursorNextPiece(Cursor cursor) =>
      blocks[cursor.blockIndex].pieces[cursor.pieceIndex + 1];

  /// Return a new cursor one character to the right from a given one.
  EditorState moveCursorRightOnce() {
    if (!cursor.isAtPieceEnd(this)) {
      return copyWith(
        cursor: cursor.copyWith(offset: cursor.offset + 1),
      );
    } else {
      // At the end of a piece, must jump.
      if (cursor.pieceIndex < getCursorBlock(cursor).pieces.length - 1) {
        // Not yet on the last piece.
        return copyWith(
          cursor: cursor.copyWith(
            pieceIndex: cursor.pieceIndex + 1,
            offset: 0,
          ),
        );
      } else {
        if (blocks.last != getCursorBlock(cursor)) {
          // There is another block to jump to.
          return copyWith(
            cursor: Cursor(
              blockIndex: cursor.blockIndex + 1,
              pieceIndex: 0,
              offset: 0,
            ),
          );
        }
        // Can't move right, returning cursor unchanged.
        return this;
      }
    }
  }

  /// Move the cursor left by one character.
  EditorState moveCursorLeftOnce() {
    if (!cursor.isAtPieceStart) {
      return copyWith(
        cursor: cursor.copyWith(offset: cursor.offset - 1),
      );
    } else {
      // At the beginning of a piece, must jump.
      if (cursor.pieceIndex > 0) {
        // Not yet on the first piece.
        return copyWith(
          cursor: cursor.copyWith(
            pieceIndex: cursor.pieceIndex - 1,
            offset: getCursorPreviousPiece(cursor).text!.length - 1,
          ),
        );
      } else {
        if (getCursorBlock(cursor) != blocks.first) {
          // There is another block to jump to.
          EditorBlock previousBlock = blocks[cursor.blockIndex - 1];
          return copyWith(
            cursor: Cursor(
              blockIndex: cursor.blockIndex - 1,
              pieceIndex: previousBlock.pieces.length - 1,
              offset: previousBlock.pieces.last.text!.length - 1,
            ),
          );
        }
        // Can't move right, returning cursor unchanged.
        return this;
      }
    }
  }

  /// Move the cursor left by a given distance.
  /// To move by one character use [moveCursorLeftOnce].
  EditorState moveCursorLeft(int distance) {
    EditorState curr = this;
    for (int i = 0; i < distance; i++) {
      curr = curr.moveCursorLeftOnce();
    }
    return curr;
  }

  /// Move the cursor right by a given distance.
  /// To move by one character use [moveCursorRightOnce].
  EditorState moveCursorRight(int distance) {
    EditorState curr = this;
    for (int i = 0; i < distance; i++) {
      curr = curr.moveCursorRightOnce();
    }
    return curr;
  }

  /// Splits the piece which contains the cursor,
  /// so the cursor is at offset zero afterwards.
  EditorState splitBeforeCursor() {
    if (cursor.offset == 0) return this;
    return insertPieceInCursorBlock(
      cursor.pieceIndex,
      TextSpan(
        text: getCursorPiece(cursor).text!.substring(0, cursor.offset),
        style: getCursorPiece(cursor).style,
      ),
    )
        .replacePieceInCursorBlock(
          cursor.pieceIndex + 1,
          TextSpan(
            text: getCursorPiece(cursor).text!.substring(cursor.offset),
            style: getCursorPiece(cursor).style,
          ),
        )
        .replaceCursor(
          pieceIndex: cursor.pieceIndex + 1,
          offset: 0,
        );
  }

  /// Insert a "hard break".
  /// Split the block at the current cursor.
  EditorState newLine() {
    final splitState = splitBeforeCursor();
    assert(splitState.cursor.offset == 0);
    final blockCut = splitState.replacePiecesInCursorBlock(
      splitState
          .getCursorBlock(splitState.cursor)
          .pieces
          .sublist(0, splitState.cursor.pieceIndex)
          .add(EditorBlock.sentinelPiece),
    );

    return blockCut.copyWith(
      blocks: blockCut.blocks.insert(
        blockCut.cursor.blockIndex + 1,
        ParagraphBlock(
          splitState
              .getCursorBlock(splitState.cursor)
              .pieces
              .sublist(splitState.cursor.pieceIndex),
        ),
      ),
      cursor: cursor.copyWith(
        blockIndex: cursor.blockIndex + 1,
        pieceIndex: 0,
        offset: 0,
      ),
    );
  }

  EditorState replacePiecesInCursorBlock(IList<TextSpan> pieces) {
    return copyWith(
      blocks: blocks.replace(
        cursor.blockIndex,
        getCursorBlock(cursor).copyWith(
          pieces: pieces,
        ),
      ),
    );
  }

  EditorState replacePieceInCursorBlock(int pieceIndex, TextSpan newPiece) {
    return replacePiecesInCursorBlock(getCursorBlock(cursor).pieces.replace(
          pieceIndex,
          newPiece,
        ));
  }

  EditorState insertPieceInCursorBlock(int pieceIndex, TextSpan newPiece) {
    return replacePiecesInCursorBlock(
        getCursorBlock(cursor).pieces.insert(pieceIndex, newPiece));
  }

  EditorState replaceCursor({
    int? blockIndex,
    int? pieceIndex,
    int? offset,
  }) {
    return copyWith(
        cursor: cursor.copyWith(
      blockIndex: blockIndex,
      pieceIndex: pieceIndex,
      offset: offset,
    ));
  }

  EditorState deleteBackwards() {
    if (cursor.isAtPieceStart) {
      // Cursor at the start means you can simply cut the last character off the previous piece.
      if (cursor.pieceIndex > 0) {
        // There is a previous piece
        if (getCursorPreviousPiece(cursor).text!.length == 1) {
          // Piece will be empty, simply remove it.
          return replacePiecesInCursorBlock(
            getCursorBlock(cursor).pieces.removeAt(cursor.pieceIndex - 1),
          ).replaceCursor(pieceIndex: cursor.pieceIndex - 1);
        } else {
          // Previous piece will not be empty, cut its last character.
          return replacePieceInCursorBlock(
            cursor.pieceIndex - 1,
            TextSpan(
              style: getCursorPreviousPiece(cursor).style,
              text: getCursorPreviousPiece(cursor).text!.substring(
                    0,
                    getCursorPreviousPiece(cursor).text!.length - 1,
                  ),
            ),
          );
        }
      } else {
        // TODO: Delete at the start of the block. This should probably transform the block into a [ParagraphBlock] and / or merge it with the previous one.
        return this;
      }
    } else if (cursor.offset == 1) {
      // Cursor on the second character means you can simply cut the first character off the current piece.
      return replacePieceInCursorBlock(
        cursor.pieceIndex,
        TextSpan(
          style: getCursorPiece(cursor).style,
          text: getCursorPiece(cursor).text!.substring(1),
        ),
      ).replaceCursor(offset: 0);
    } else {
      // Cursor in the middle of a piece, split required.
      return insertPieceInCursorBlock(
        cursor.pieceIndex,
        TextSpan(
          style: getCursorPiece(cursor).style,
          text: getCursorPiece(cursor).text!.substring(
                0,
                cursor.offset - 1,
              ),
        ),
      )
          .replacePieceInCursorBlock(
            cursor.pieceIndex + 1,
            TextSpan(
              style: getCursorPiece(cursor).style,
              text: getCursorPiece(cursor).text!.substring(cursor.offset),
            ),
          )
          .replaceCursor(
            pieceIndex: cursor.pieceIndex + 1,
            offset: 0,
          );
    }
  }

  /// Insert [newContent] before the cursor.
  EditorState append(String newContent) {
    if (cursor.isAtPieceStart) {
      if (cursor.pieceIndex == 0) {
        // There is no previous piece, insert one.
        return insertPieceInCursorBlock(
          0,
          TextSpan(
            text: newContent,
            style: getCursorPiece(cursor).style,
          ),
        ).replaceCursor(
          pieceIndex: 1,
        ); // Cursor remains where it is, but the index changes because another piece was inserted in front.
      } else {
        // Append to the previous piece.
        return replacePieceInCursorBlock(
          cursor.pieceIndex - 1,
          TextSpan(
            text: getCursorPreviousPiece(cursor).text! + newContent,
            style: getCursorPreviousPiece(cursor).style,
          ),
        );
      }
    } else {
      // Cursor is not at the start, piece must be split.
      // Insert first half.
      return insertPieceInCursorBlock(
        cursor.pieceIndex,
        TextSpan(
          text: getCursorPiece(cursor).text!.substring(0, cursor.offset) +
              newContent,
          style: getCursorPiece(cursor).style,
        ),
      )
          .replacePieceInCursorBlock(
            // Append to the second half.
            cursor.pieceIndex + 1,
            TextSpan(
              text: getCursorPiece(cursor).text!.substring(cursor.offset),
              style: getCursorPiece(cursor).style,
            ),
          ) // Cursor remains where it is, but the index changes because another piece was inserted in front.
          .replaceCursor(
            pieceIndex: cursor.pieceIndex + 1,
            offset: 0,
          );
    }
  }
}
