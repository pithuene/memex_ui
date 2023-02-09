import 'dart:async';

import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/memex_ui.dart';

import './cursor.dart';
import './block.dart';

import 'package:flutter/material.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

@immutable
class Selection {
  final Cursor? start;
  final Cursor end;
  const Selection({
    this.start,
    required this.end,
  });

  bool get isEmpty => start == null;

  /// Either [start] or [end], whichever comes first in the document.
  Cursor get first => (end.isBefore(start!)) ? end : start!;

  /// Either [start] or [end], whichever comes later in the document.
  Cursor get last => (end.isBefore(start!)) ? start! : end;

  /// Whether the selection crosses a given [block].
  bool containsBlock(BlockPath block) {
    if (isEmpty) return false;
    if (last.blockPath.compareTo(block) >= 0 &&
        first.blockPath.compareTo(block) <= 0) {
      return true;
    } else {
      return false;
    }
  }
}

/// A persistent datastructure representing the entire state
/// of a rich text editor including content
/// aswell as cursor and selection.
class EditorState {
  /// The top level blocks of the editor.
  late final IList<EditorBlock> blocks;

  /// If there is a selection, this marks its start.
  /// The selection ends at [cursor].
  final Cursor? selectionStart;

  /// Location of the caret.
  /// Also marks the end of the current selection.
  late final Cursor cursor;

  bool get hasSelection => selectionStart != null;

  EditorState.withInitialContent(String? initialContent)
      : selectionStart = null {
    blocks = <EditorBlock>[
      SectionBlock.withInitialContent(initialContent),
      ParagraphBlock.withInitialContent(
        initialContent: "Ein neuer Absatz.",
      ),
      BulletpointBlock.withInitialContent("Eins"),
    ].lockUnsafe;
    cursor = Cursor(
      blockPath: BlockPath.constant(const [0]),
      pieceIndex: 0,
      offset: 0,
    );
  }

  EditorState({
    required this.blocks,
    required this.cursor,
    this.selectionStart,
  });

  EditorState removeSelection() => EditorState(
        blocks: blocks,
        selectionStart: null,
        cursor: cursor,
      );

  EditorState copyWith({
    IList<EditorBlock>? blocks,
    Cursor? cursor,
    Cursor? selectionStart,
  }) {
    return EditorState(
      blocks: blocks ?? this.blocks,
      selectionStart: selectionStart ?? this.selectionStart,
      cursor: cursor ?? this.cursor,
    );
  }

  EditorBlock? getBlockFromPath(BlockPath blockPath) {
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

  /// Start a selection at the current [cursor].
  EditorState beginSelection() => copyWith(selectionStart: cursor);

  /// Called before beginning a cursor movement.
  /// Handles selection state.
  EditorState beginCursorMove(bool isSelecting) {
    if (!hasSelection && isSelecting) {
      return beginSelection();
    } else if (hasSelection && !isSelecting) {
      return removeSelection();
    } else {
      return this;
    }
  }

  /// Return a new cursor one character to the right from a given one.
  EditorState moveCursorRightOnce(bool isSelecting) {
    EditorState state = beginCursorMove(isSelecting);

    if (!hasSelection && isSelecting) {
      state = beginSelection();
    } else if (hasSelection && !isSelecting) {
      state = removeSelection();
    } else {
      state = this;
    }

    if (!cursor.isAtPieceEnd(this)) {
      return state.replaceCursor(offset: cursor.offset + 1);
    }
    // At the end of a piece, must jump.
    if (!cursor.isOnLastPiece(this)) {
      return state.replaceCursor(
        pieceIndex: cursor.pieceIndex + 1,
        offset: 0,
      );
    }
    // On the last piece, must jump to next block.
    BlockPath? nextBlockPath = cursor.blockPath.next(this);
    if (nextBlockPath == null) {
      // Can't move, this is the last block.
      return state;
    }
    // There is another block to jump to.
    return state.replaceCursor(
      blockPath: nextBlockPath,
      pieceIndex: 0,
      offset: 0,
    );
  }

  /// Move the cursor left by one character.
  EditorState moveCursorLeftOnce(bool isSelecting) {
    EditorState state = beginCursorMove(isSelecting);

    if (!cursor.isAtPieceStart) {
      return state.replaceCursor(offset: cursor.offset - 1);
    }
    // At the beginning of a piece, must jump.

    if (!cursor.isOnFirstPiece) {
      return state.copyWith(
        cursor: cursor.copyWith(
          pieceIndex: cursor.pieceIndex - 1,
          offset: getCursorPreviousPiece(cursor).text!.length - 1,
        ),
      );
    }
    // On the first piece, must jump to the previous block.

    BlockPath? previousBlockPath = cursor.blockPath.previous(this);
    if (previousBlockPath == null) {
      // Can't move, this is the first block.
      return state;
    }
    // There is another block to jump to.

    EditorBlock previousBlock = getBlockFromPath(previousBlockPath)!;
    return state.replaceCursor(
      blockPath: previousBlockPath,
      pieceIndex: previousBlock.pieces.length - 1,
      offset: previousBlock.pieces.last.text!.length - 1,
    );
  }

  /// Move the cursor left by a given distance.
  /// To move by one character use [moveCursorLeftOnce].
  EditorState moveCursorLeft(int distance, bool isSelecting) {
    EditorState curr = this;
    for (int i = 0; i < distance; i++) {
      curr = curr.moveCursorLeftOnce(isSelecting);
    }
    return curr;
  }

  /// Move the cursor right by a given distance.
  /// To move by one character use [moveCursorRightOnce].
  EditorState moveCursorRight(int distance, bool isSelecting) {
    EditorState curr = this;
    for (int i = 0; i < distance; i++) {
      curr = curr.moveCursorRightOnce(isSelecting);
    }
    return curr;
  }

  /// Splits the piece which contains the cursor,
  /// so the cursor is at offset zero afterwards.
  EditorState splitBeforeCursor() {
    if (cursor.isAtPieceStart) return this;

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
    assert(splitState.cursor.isAtPieceStart);
    final blockCut = splitState.replacePiecesInCursorBlock(
      (pieces) => pieces
          .sublist(0, splitState.cursor.pieceIndex)
          .add(EditorBlock.sentinelPiece),
    );

    final BlockPath newBlockPath = cursor.blockPath.nextNeighbor();

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

    if (cursorBlock is EditorBlockWithChildren) {
      // Move children into the new block.
      // The new block already contains the children,
      // because the have been copied from the old one.
      // Remove children from old block.
      return newBlockInserted.clearBlockChildren(cursor.blockPath);
    }

    return newBlockInserted;
  }

  /// Transform the block at a given [blockPath]
  /// throguh a [blockChange] function.
  EditorState replaceBlockAtPath(
    BlockPath blockPath,
    EditorBlock Function(EditorBlock) blockChange,
  ) {
    /// Replace a block at [blockPath] in a tree of [blocks] with a [newBlock].
    IList<EditorBlock> replaceBlockInBlocksAtPath(
      IList<EditorBlock> blocks,
      BlockPath blockPath,
      EditorBlock newBlock,
    ) {
      if (blockPath.isTopLevel) {
        return blocks.replace(blockPath[0], newBlock);
      }
      return blocks.replace(
        blockPath[0],
        (blocks[blockPath[0]] as EditorBlockWithChildren).replaceChildren(
          (children) => replaceBlockInBlocksAtPath(
            children,
            blockPath.sublist(1),
            newBlock,
          ),
        ),
      );
    }

    if (blockPath.isTopLevel) {
      return copyWith(
        blocks: blocks.replace(
          blockPath.single,
          blockChange(getBlockFromPath(blockPath)!),
        ),
      );
    }

    return copyWith(
      blocks: replaceBlockInBlocksAtPath(
        blocks,
        blockPath,
        blockChange(getBlockFromPath(blockPath)!),
      ),
    );
  }

  /// Insert a [newBlock] at a given [blockPath].
  EditorState insertBlockAtPath(BlockPath blockPath, EditorBlock newBlock) {
    if (blockPath.isTopLevel) {
      return copyWith(blocks: blocks.insert(blockPath.single, newBlock));
    }

    BlockPath parentPath = blockPath.parent();
    return replaceBlockAtPath(
      parentPath,
      (parentBlock) => (parentBlock as EditorBlockWithChildren).replaceChildren(
        (children) => children.insert(
          blockPath.last,
          newBlock,
        ),
      ),
    );
  }

  /// Remove the block at a given [blockPath].
  EditorState removeBlockAtPath(BlockPath blockPath) {
    if (blockPath.length == 1) {
      return copyWith(
        blocks: blocks.removeAt(blockPath.single),
      );
    }

    BlockPath parentPath = blockPath.parent();
    return replaceBlockAtPath(
      parentPath,
      (parentBlock) => (parentBlock as EditorBlockWithChildren)
          .replaceChildren((children) => children.removeAt(blockPath.last)),
    );
  }

  EditorState replacePiecesInCursorBlock(
    IList<TextSpan> Function(IList<TextSpan>) pieceChange,
  ) {
    return replaceBlockAtPath(
      cursor.blockPath,
      (cursorBlock) => cursorBlock.replacePieces(pieceChange),
    );
  }

  EditorState replacePieceInCursorBlock(int pieceIndex, TextSpan newPiece) {
    return replacePiecesInCursorBlock(
      (pieces) => pieces.replace(
        pieceIndex,
        newPiece,
      ),
    );
  }

  EditorState insertPieceInCursorBlock(int pieceIndex, TextSpan newPiece) {
    return replacePiecesInCursorBlock(
      (pieces) => pieces.insert(pieceIndex, newPiece),
    );
  }

  EditorState replaceCursor({
    BlockPath? blockPath,
    int? pieceIndex,
    int? offset,
  }) {
    return copyWith(
      cursor: cursor.copyWith(
        blockPath: blockPath,
        pieceIndex: pieceIndex,
        offset: offset,
      ),
    );
  }

  /// Append the content of the block at [blockPathToRemove] to the previous block and delete it.
  EditorState mergeWithPreviousBlock(BlockPath blockPathToRemove) {
    EditorBlock blockToRemove = getBlockFromPath(blockPathToRemove)!;

    // Turn block into ParagraphBlock before merging it with anything.
    assert(blockToRemove.runtimeType == ParagraphBlock);

    // TODO: What if the previous block can't be merged with (is an image or something)? Notion just skips it in that case and merges with what is before that.

    BlockPath? previousBlockPath = blockPathToRemove.previous(this);
    if (previousBlockPath == null) {
      // There is no previous block to merge with.
      return this;
    }

    int cursorPieceIndexAferMerge =
        getBlockFromPath(previousBlockPath)!.pieces.length - 1;

    return replaceBlockAtPath(
      previousBlockPath,
      (previousBlock) => previousBlock.replacePieces(
        (pieces) => pieces.removeLast().addAll(blockToRemove.pieces),
      ),
    ).removeBlockAtPath(blockPathToRemove).replaceCursor(
          blockPath: previousBlockPath,
          pieceIndex: cursorPieceIndexAferMerge,
          offset: 0,
        );
  }

  /// Remove all children of the block at [blockPath].
  EditorState clearBlockChildren(BlockPath blockPath) {
    assert(getBlockFromPath(blockPath)! is EditorBlockWithChildren);
    return replaceBlockAtPath(
      blockPath,
      (targetBlock) => (targetBlock as EditorBlockWithChildren)
          .replaceChildren((children) => <EditorBlock>[].lockUnsafe),
    );
  }

  /// Insert a list of [newBlocks] at a [destinationBlockPath].
  EditorState insertBlocks(
    BlockPath destinationBlockPath,
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
    BlockPath blockPathToReplace,
    IList<EditorBlock> replacementBlocks,
  ) {
    EditorState resultState = removeBlockAtPath(blockPathToReplace);
    return resultState.insertBlocks(blockPathToReplace, replacementBlocks);
  }

  /// Called through [deleteBackwards] at the start of a non-paragraph block.
  EditorState turnBlockIntoParagraphBlock(BlockPath blockPath) {
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
            (pieces) => pieces.removeAt(cursor.pieceIndex - 1),
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

  EditorState markdownShortcutBulletpoint() {
    EditorBlock newBulletpointBlock =
        (getCursorBlock(cursor) as ParagraphBlock).turnIntoBulletpointBlock();
    // Remove the first piece, which triggered the transformation.
    newBulletpointBlock = newBulletpointBlock.replacePieces(
      (pieces) => pieces.removeAt(0),
    );

    return replaceBlockWithBlocks(
      cursor.blockPath,
      <EditorBlock>[newBulletpointBlock].lockUnsafe,
    ).replaceCursor(
      pieceIndex: 0,
      offset: 0,
    );
  }

  EditorState markdownShortcutH1() {
    EditorBlock newSectionBlock =
        (getCursorBlock(cursor) as ParagraphBlock).turnIntoSectionBlock();

    // Remove the first piece, which triggered the transformation.
    newSectionBlock = newSectionBlock.replacePieces(
      (pieces) => pieces.removeAt(0),
    );

    final withSectionBlock = replaceBlockWithBlocks(
      cursor.blockPath,
      <EditorBlock>[newSectionBlock].lockUnsafe,
    );

    return withSectionBlock.replaceCursor(
      pieceIndex: 0,
      offset: 0,
    );
  }

  /// Indent the current block.
  /// Usually makes it a child of its preceeding neighbor.
  EditorState indent() {
    EditorBlock cursorBlock = getCursorBlock(cursor);
    if (cursorBlock is BulletpointBlock) {
      BlockPath preceedingNeighborPath = cursor.blockPath.previousNeighbor();
      EditorBlock? preceedingNeighbor =
          getBlockFromPath(preceedingNeighborPath);
      if (preceedingNeighbor == null) {
        // There is no preceeding neighbor to which this can be added.
        return this;
      }
      if (preceedingNeighbor is! BulletpointBlock) {
        // TODO: This should also check for other list blocks.
        return this;
      }
      BlockPath destinationBlockPath =
          preceedingNeighborPath.add(preceedingNeighbor.children.length);
      return insertBlockAtPath(destinationBlockPath, cursorBlock)
          .removeBlockAtPath(cursor.blockPath)
          .replaceCursor(blockPath: destinationBlockPath);
    }
    return this;
  }

  /// Unindent the current block.
  /// Usually makes it a neighbor of its parent.
  EditorState unindent() {
    BlockPath destinationPath = cursor.blockPath.parent();
    if (destinationPath.isEmpty) {
      // Can't indent, already top level block.
      return this;
    }
    destinationPath = destinationPath.replace(
      destinationPath.length - 1,
      destinationPath.last + 1,
    );

    return insertBlockAtPath(destinationPath, getCursorBlock(cursor))
        .removeBlockAtPath(cursor.blockPath)
        .replaceCursor(blockPath: destinationPath);
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
          return markdownShortcutH1();
        }
        if (newContent == " " &&
            cursor.pieceIndex == 1 &&
            getCursorBlock(cursor).runtimeType == ParagraphBlock &&
            getCursorPreviousPiece(cursor).text!.trim() == "-") {
          // Space after a - at the start of a [ParagraphBlock]
          // => Transform this [ParagraphBlock] into a [BulletpointBlock].
          return markdownShortcutBulletpoint();
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
