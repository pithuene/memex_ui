import './cursor.dart';
import './block.dart';

import 'package:flutter/material.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class Editor {
  /// The top level blocks of the editor.
  late IList<EditorBlock> blocks;
  late Cursor cursor;

  Editor({
    String? initialContent,
  }) {
    blocks = [
      ParagraphBlock(
        initialContent: initialContent,
        editor: this,
      ),
      ParagraphBlock(
        initialContent: "Ein neuer Absatz.",
        editor: this,
      ),
    ].lockUnsafe;
    cursor = Cursor(
      block: blocks[0],
      pieceIndex: 0,
      offset: 0,
    );
  }

  /// Return a new cursor one character to the right from a given one.
  Cursor moveRightOnce(Cursor cursor) {
    if (!cursor.isAtPieceEnd) {
      return cursor.copyWith(offset: cursor.offset + 1);
    } else {
      // At the end of a piece, must jump.
      if (cursor.pieceIndex < cursor.block.pieces.length - 1) {
        // Not yet on the last piece.
        return cursor.copyWith(
          pieceIndex: cursor.pieceIndex + 1,
          offset: 0,
        );
      } else {
        if (blocks.last != cursor.block) {
          // There is another block to jump to.
          return Cursor(
            block: blocks[blocks.indexOf(cursor.block) + 1],
            pieceIndex: 0,
            offset: 0,
          );
        }
        // Can't move right, returning cursor unchanged.
        return cursor;
      }
    }
  }

  /// Move the cursor left by one character.
  Cursor moveLeftOnce(Cursor cursor) {
    if (!cursor.isAtPieceStart) {
      return cursor.copyWith(offset: cursor.offset - 1);
    } else {
      // At the beginning of a piece, must jump.
      if (cursor.pieceIndex > 0) {
        // Not yet on the first piece.
        return cursor.copyWith(
          pieceIndex: cursor.pieceIndex - 1,
          offset: cursor.block.pieces[cursor.pieceIndex - 1].text!.length - 1,
        );
      } else {
        if (blocks.first != cursor.block) {
          // There is another block to jump to.
          return Cursor(
            block: blocks.first,
            pieceIndex: blocks.first.pieces.length - 1,
            offset: blocks.first.pieces.last.text!.length - 1,
          );
        }
        // Can't move right, returning cursor unchanged.
        return cursor;
      }
    }
  }

  /// Move the cursor left by a given distance.
  /// To move by one character use [moveLeftOnce].
  Cursor moveLeft(int distance, Cursor cursor) {
    Cursor curr = cursor;
    for (int i = 0; i < distance; i++) {
      curr = moveLeftOnce(cursor);
    }
    return curr;
  }

  /// Move the cursor right by a given distance.
  /// To move by one character use [moveRightOnce].
  Cursor moveRight(int distance, Cursor cursor) {
    Cursor curr = cursor;
    for (int i = 0; i < distance; i++) {
      curr = moveRightOnce(curr);
    }
    return curr;
  }

  void deleteBackwards() {
    if (cursor.isAtPieceStart) {
      // Cursor at the start means you can simply cut the last character off the previous piece.
      if (cursor.previousPiece != null) {
        if (cursor.previousPiece!.text!.length == 1) {
          // Piece will be empty, simply remove it.
          cursor.block.pieces =
              cursor.block.pieces.removeAt(cursor.pieceIndex - 1);
          cursor = cursor.copyWith(pieceIndex: cursor.pieceIndex - 1);
        } else {
          cursor.block.pieces = cursor.block.pieces.replace(
            cursor.pieceIndex - 1,
            TextSpan(
                style: cursor.previousPiece!.style,
                text: cursor.previousPiece!.text!
                    .substring(0, cursor.previousPiece!.text!.length - 1)),
          );
        }
      } else {
        // TODO: Delete at the start of the block. This should probably transform the block into a [ParagraphBlock] and / or merge it with the previous one.
      }
    } else if (cursor.offset == 1) {
      // Cursor on the second character means you can simply cut the first character off the current piece.
      cursor.block.pieces = cursor.block.pieces.replace(
        cursor.pieceIndex,
        TextSpan(
          style: cursor.piece.style,
          text: cursor.piece.text!.substring(1),
        ),
      );
      cursor = cursor.copyWith(offset: 0);
    } else {
      // Spit required
      // Insert first half
      cursor.block.pieces = cursor.block.pieces.insert(
        cursor.pieceIndex,
        TextSpan(
          style: cursor.piece.style,
          text: cursor.piece.text!.substring(
            0,
            cursor.offset - 1,
          ),
        ),
      );
      // Cut second half
      cursor.block.pieces = cursor.block.pieces.replace(
        cursor.pieceIndex + 1,
        TextSpan(
          style: cursor.nextPiece!.style,
          text: cursor.nextPiece!.text!.substring(cursor.offset),
        ),
      );
      // Adjust cursor.
      cursor = cursor.copyWith(
        pieceIndex: cursor.pieceIndex + 1,
        offset: 0,
      );
    }
  }

  /// Insert [newContent] before the cursor.
  void append(String newContent) {
    if (cursor.isAtPieceStart) {
      if (cursor.pieceIndex == 0) {
        // There is no previous piece, insert one.
        TextSpan cursorPiece = cursor.block.pieces[cursor.pieceIndex];
        cursor.block.pieces = cursor.block.pieces.insert(
          0,
          TextSpan(
            text: newContent,
            style: cursorPiece.style,
          ),
        );
        // Cursor remains where it is, but the index changes because another piece was inserted in front.
        cursor = cursor.copyWith(pieceIndex: 1);
      } else {
        // Append to the previous piece.
        TextSpan previousPiece = cursor.block.pieces[cursor.pieceIndex - 1];
        cursor.block.pieces = cursor.block.pieces.replace(
          cursor.pieceIndex - 1,
          TextSpan(
            text: previousPiece.text! + newContent,
            style: previousPiece.style,
          ),
        );
      }
    } else {
      // Cursor is not at the start, piece must be split.
      // Insert first half.
      cursor.block.pieces = cursor.block.pieces.insert(
        cursor.pieceIndex,
        TextSpan(
          text: cursor.block.pieces[cursor.pieceIndex].text!
                  .substring(0, cursor.offset) +
              newContent,
          style: cursor.block.pieces[cursor.pieceIndex].style,
        ),
      );
      // Append to the second half.
      cursor.block.pieces = cursor.block.pieces.replace(
        cursor.pieceIndex + 1,
        TextSpan(
          text: cursor.block.pieces[cursor.pieceIndex + 1].text!
              .substring(cursor.offset),
          style: cursor.block.pieces[cursor.pieceIndex + 1].style,
        ),
      );
      // Cursor remains where it is, but the index changes because
      // another piece was inserted in front.
      cursor = cursor.copyWith(
        pieceIndex: cursor.pieceIndex + 1,
        offset: 0,
      );
    }
  }
}
