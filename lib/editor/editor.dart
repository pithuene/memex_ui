import 'dart:async';

import './cursor.dart';
import './block.dart';

import 'package:flutter/material.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class Editor {
  EditorState state;
  Editor(this.state);

  List<EditorState> undoStack = [];
  List<EditorState> redoStack = [];

  /// Emits every time the cursor or selection changes.
  /// Used for rebuilding.
  StreamController<void> onCursorChange = StreamController.broadcast();

  // Non reversable actions
  void moveCursorRightOnce() => state = state.moveCursorRightOnce();
  void moveCursorLeftOnce() => state = state.moveCursorLeftOnce();

  void _performReversableAction(EditorState newState) {
    undoStack.add(state);
    redoStack.clear();
    state = newState;
  }

  // Reversable actions
  void append(String content) =>
      _performReversableAction(state.append(content));

  void deleteBackwards() => _performReversableAction(state.deleteBackwards());

  // TODO: Name newBlock?
  void newLine() => _performReversableAction(state.newLine());

  // Undo / Redo
  void undo() {
    if (undoStack.isEmpty) return;
    redoStack.add(state);
    state = undoStack.removeLast();
  }

  void redo() {
    if (redoStack.isEmpty) return;
    undoStack.add(state);
    state = redoStack.removeLast();
  }
}

class EditorState {
  /// The top level blocks of the editor.
  late final IList<EditorBlock> blocks;
  late final Cursor cursor;

  EditorState.withInitialContent(String? initialContent) {
    blocks = <EditorBlock>[
      SectionBlock.withInitialContent(initialContent),
      ParagraphBlock.withInitialContent(
        initialContent: "Ein neuer Absatz.",
      ),
    ].lockUnsafe;
    cursor = const Cursor(
      blockPath: IListConst([0]),
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

  EditorBlock? getBlockFromPath(IList<int> blockPath) {
    if (blockPath.isEmpty) return null;
    EditorBlock? curr = blocks.getOrNull(blockPath[0]);
    for (int i = 1; i < blockPath.length; i++) {
      if (curr == null) return null;
      if (curr is! EditorBlockWithChildren) return null;
      curr = curr.children.getOrNull(blockPath[i]);
    }
    return curr;
  }

  EditorBlock getCursorBlock(Cursor cursor) {
    return getBlockFromPath(cursor.blockPath)!;
  }

  TextSpan getCursorPiece(Cursor cursor) =>
      getCursorBlock(cursor).pieces[cursor.pieceIndex];

  TextSpan getCursorPreviousPiece(Cursor cursor) =>
      getCursorBlock(cursor).pieces[cursor.pieceIndex - 1];

  TextSpan getCursorNextPiece(Cursor cursor) =>
      getCursorBlock(cursor).pieces[cursor.pieceIndex + 1];

  /// Find the block path to the next block.
  /// Returns null if this is the last block.
  IList<int>? getNextBlock(IList<int> blockPath) {
    EditorBlock currentBlock = getBlockFromPath(blockPath)!;
    if (currentBlock is EditorBlockWithChildren &&
        currentBlock.children.isNotEmpty) {
      // Return path to first child.
      return blockPath.add(0);
    } else {
      IList<int> nextPath =
          blockPath.replace(blockPath.length - 1, blockPath.last + 1);
      EditorBlock? next = getBlockFromPath(nextPath);
      while (next == null && nextPath.length > 1) {
        nextPath = nextPath.removeLast();
        nextPath = nextPath.replace(nextPath.length - 1, nextPath.last + 1);
        next = getBlockFromPath(nextPath);
      }
      if (next == null) return null;
      return nextPath;
    }
  }

  /// Find the block path to the previous block.
  /// Returns null if this is the first block.
  IList<int>? getPreviousBlock(IList<int> blockPath) {
    if (blockPath.length == 1 && blockPath[0] == 0) {
      // First block, there is no previous one.
      return null;
    }

    if (blockPath.last > 0) {
      // Has previous neighbor
      IList<int> previousBlockPath =
          blockPath.replace(blockPath.length - 1, blockPath.last - 1);
      EditorBlock previousBlock = getBlockFromPath(previousBlockPath)!;
      // Get previous neighbors last child
      while (previousBlock is EditorBlockWithChildren &&
          previousBlock.children.isNotEmpty) {
        previousBlockPath =
            previousBlockPath.add(previousBlock.children.length - 1);
        previousBlock = getBlockFromPath(previousBlockPath)!;
      }
      return previousBlockPath;
    } else {
      return blockPath.removeLast();
    }
  }

  /// Return a new cursor one character to the right from a given one.
  EditorState moveCursorRightOnce() {
    if (!cursor.isAtPieceEnd(this)) {
      return replaceCursor(offset: cursor.offset + 1);
    } else {
      // At the end of a piece, must jump.
      if (cursor.pieceIndex < getCursorBlock(cursor).pieces.length - 1) {
        // Not yet on the last piece.
        return replaceCursor(
          pieceIndex: cursor.pieceIndex + 1,
          offset: 0,
        );
      } else {
        // On the last piece, must jump to next block.
        IList<int>? nextBlockPath = getNextBlock(cursor.blockPath);
        if (nextBlockPath == null) {
          // Can't move, this is the last block.
          return this;
        } else {
          // There is another block to jump to.
          return replaceCursor(
            blockPath: nextBlockPath,
            pieceIndex: 0,
            offset: 0,
          );
        }
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
        // On the first piece, must jump to the previous block.
        IList<int>? previousBlockPath = getPreviousBlock(cursor.blockPath);
        if (previousBlockPath == null) {
          // Can't move, this is the first block.
          return this;
        } else {
          // There is another block to jump to.
          EditorBlock previousBlock = getBlockFromPath(previousBlockPath)!;
          return replaceCursor(
            blockPath: previousBlockPath,
            pieceIndex: previousBlock.pieces.length - 1,
            offset: previousBlock.pieces.last.text!.length - 1,
          );
        }
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

    final IList<int> newBlockPath = cursor.blockPath.replace(
      cursor.blockPath.length - 1,
      cursor.blockPath.last + 1,
    );

    EditorBlock cursorBlock = getCursorBlock(cursor);
    final newBlockInserted = blockCut
        .insertBlockAtPath(
          newBlockPath,
          cursorBlock.copyWith(
            pieces: splitState
                .getCursorBlock(splitState.cursor)
                .pieces
                .sublist(splitState.cursor.pieceIndex),
          ),
        )
        .replaceCursor(
          blockPath: newBlockPath,
          pieceIndex: 0,
          offset: 0,
        );

    if (cursorBlock is! EditorBlockWithChildren) {
      return newBlockInserted;
    } else {
      // Move children into the new block.
      // The new block already contains the children,
      // because the have been copied from the old one.
      // Remove children from old block.
      return newBlockInserted.clearBlockChildren(cursor.blockPath);
    }
  }

  /// Replace a block at [blockPath] in a tree of [blocks] with a [newBlock].
  IList<EditorBlock> replaceBlockInBlocksAtPath(
    IList<EditorBlock> blocks,
    IList<int> blockPath,
    EditorBlock newBlock,
  ) {
    if (blockPath.length == 1) {
      return blocks.replace(blockPath[0], newBlock);
    }
    return blocks.replace(
      blockPath[0],
      (blocks[blockPath[0]] as EditorBlockWithChildren).copyWith(
        children: replaceBlockInBlocksAtPath(
          (blocks[blockPath[0]] as EditorBlockWithChildren).children,
          blockPath.sublist(1),
          newBlock,
        ),
      ),
    );
  }

  /// Replace the block at a given [blockPath] with a [newBlock].
  EditorState replaceBlockAtPath(IList<int> blockPath, EditorBlock newBlock) {
    if (blockPath.length == 1) {
      return copyWith(
        blocks: blocks.replace(blockPath.single, newBlock),
      );
    }

    return copyWith(
      blocks: replaceBlockInBlocksAtPath(
        blocks,
        blockPath,
        newBlock,
      ),
    );
  }

  /// Insert a [newBlock] at a given [blockPath].
  EditorState insertBlockAtPath(IList<int> blockPath, EditorBlock newBlock) {
    if (blockPath.length == 1) {
      return copyWith(
        blocks: blocks.insert(blockPath.single, newBlock),
      );
    }

    IList<int> parentPath = blockPath.removeLast();
    return replaceBlockAtPath(
      parentPath,
      (getBlockFromPath(parentPath) as EditorBlockWithChildren).copyWith(
        children: (getBlockFromPath(parentPath) as EditorBlockWithChildren)
            .children
            .insert(
              blockPath.last,
              newBlock,
            ),
      ),
    );
  }

  /// Remove the block at a given [blockPath].
  EditorState removeBlockAtPath(IList<int> blockPath) {
    if (blockPath.length == 1) {
      return copyWith(
        blocks: blocks.removeAt(blockPath.single),
      );
    }

    IList<int> parentPath = blockPath.removeLast();
    return replaceBlockAtPath(
      parentPath,
      (getBlockFromPath(parentPath) as EditorBlockWithChildren).copyWith(
        children: (getBlockFromPath(parentPath) as EditorBlockWithChildren)
            .children
            .removeAt(blockPath.last),
      ),
    );
  }

  EditorState replacePiecesInCursorBlock(IList<TextSpan> pieces) {
    return replaceBlockAtPath(
      cursor.blockPath,
      getCursorBlock(cursor).copyWith(
        pieces: pieces,
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
    IList<int>? blockPath,
    int? pieceIndex,
    int? offset,
  }) {
    return copyWith(
        cursor: cursor.copyWith(
      blockPath: blockPath,
      pieceIndex: pieceIndex,
      offset: offset,
    ));
  }

  /// Append the content of the block at [blockPathToRemove] to the previous block and delete it.
  EditorState mergeWithPreviousBlock(IList<int> blockPathToRemove) {
    EditorBlock blockToRemove = getBlockFromPath(blockPathToRemove)!;

    // Turn block into ParagraphBlock before merging it with anything.
    assert(blockToRemove.runtimeType == ParagraphBlock);

    // TODO: What if the previous block can't be merged with (is an image or something)? Notion just skips it in that case and merges with what is before that.

    IList<int>? previousBlockPath = getPreviousBlock(blockPathToRemove);
    if (previousBlockPath == null) {
      // There is no previous block to merge with.
      return this;
    }
    EditorBlock previousBlock = getBlockFromPath(previousBlockPath)!;

    return replaceBlockAtPath(
      previousBlockPath,
      previousBlock.copyWith(
        pieces: previousBlock.pieces.removeLast().addAll(blockToRemove.pieces),
      ),
    ).removeBlockAtPath(blockPathToRemove).replaceCursor(
          blockPath: previousBlockPath,
          pieceIndex: previousBlock.pieces.length - 1,
          offset: 0,
        );
  }

  /// Remove all children of the block at [blockPath].
  EditorState clearBlockChildren(IList<int> blockPath) {
    EditorBlock targetBlock = getBlockFromPath(blockPath)!;
    assert(targetBlock is EditorBlockWithChildren);
    return replaceBlockAtPath(
      blockPath,
      (targetBlock as EditorBlockWithChildren).copyWith(
        children: <EditorBlock>[].lockUnsafe,
      ),
    );
  }

  /// Insert a list of [newBlocks] at a [destinationBlockPath].
  EditorState insertBlocks(
    IList<int> destinationBlockPath,
    IList<EditorBlock> newBlocks,
  ) {
    EditorState resultState = this;
    for (int i = newBlocks.length - 1; i >= 0; i--) {
      resultState = resultState.insertBlockAtPath(
        destinationBlockPath,
        newBlocks[i],
      );
    }
    return resultState;
  }

  /// Replace the block at [blockPathToReplace] with [replacementBlocks].
  EditorState replaceBlockWithBlocks(
    IList<int> blockPathToReplace,
    IList<EditorBlock> replacementBlocks,
  ) {
    EditorState resultState = removeBlockAtPath(blockPathToReplace);
    return resultState.insertBlocks(blockPathToReplace, replacementBlocks);
  }

  /// Called through [deleteBackwards] at the start of a non-paragraph block.
  EditorState turnBlockIntoParagraphBlock(IList<int> blockPath) {
    EditorBlock blockToTransform = getBlockFromPath(blockPath)!;
    IList<EditorBlock> replacementBlocks =
        blockToTransform.turnIntoParagraphBlock();
    return replaceBlockWithBlocks(blockPath, replacementBlocks);
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
        //  Delete at the start of the block.
        EditorBlock cursorBlock = getBlockFromPath(cursor.blockPath)!;
        if (cursorBlock.runtimeType != ParagraphBlock) {
          return turnBlockIntoParagraphBlock(cursor.blockPath);
        } else {
          return mergeWithPreviousBlock(cursor.blockPath);
        }
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
        if (newContent == " " &&
            cursor.pieceIndex == 1 &&
            cursor.blockPath.length == 1 &&
            getCursorBlock(cursor).runtimeType == ParagraphBlock &&
            getCursorPreviousPiece(cursor).text!.trim() == "#") {
          // Space after a # at the start of a [ParagraphBlock]
          // => Transform this [ParagraphBlock] into a [SectionBlock].

          // Find index of the next [SectionBlock].
          int? nextSectionBlockIndex;
          for (int i = cursor.blockPath.single; i < blocks.length; i++) {
            if (blocks[i].runtimeType == SectionBlock) {
              nextSectionBlockIndex = i;
              break;
            }
          }

          SectionBlock newSectionBlock =
              (getCursorBlock(cursor) as ParagraphBlock)
                  .turnIntoSectionBlock(blocks.sublist(
                      cursor.blockPath.single + 1, nextSectionBlockIndex))
                  .copyWith();
          newSectionBlock = newSectionBlock.copyWith(
            pieces: newSectionBlock.pieces.removeAt(0),
          );
          final withSectionBlock = replaceBlockWithBlocks(
            cursor.blockPath,
            <EditorBlock>[newSectionBlock].lockUnsafe,
          );

          // Remove the blocks which have been moved into the section.
          final deletedMovedBlocks = withSectionBlock.copyWith(
            blocks: withSectionBlock.blocks.removeRange(
              cursor.blockPath.single + 1,
              nextSectionBlockIndex ?? blocks.length,
            ),
          );

          return deletedMovedBlocks.replaceCursor(
            pieceIndex: 0,
            offset: 0,
          );
        }
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
