import 'dart:async';

import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/piece_path.dart';
import 'package:memex_ui/editor/pieces.dart';
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

  const Selection.collapsed(this.end) : start = null;

  bool get isEmpty => start == null;

  /// Whether there is a selection which does not cross block boundaries.
  bool get isInSingleBlock => !isEmpty && start!.blockPath == end.blockPath;

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

  /// Collapse the selection to its end.
  Selection collapse() => copyWithStart(null);

  Selection copyWithEnd(Cursor end) {
    return Selection(
      start: start,
      end: end,
    );
  }

  Selection copyWithStart(Cursor? start) {
    return Selection(
      start: start,
      end: end,
    );
  }
}

/// A persistent datastructure representing the entire state
/// of a rich text editor including content
/// aswell as cursor and selection.
class EditorState {
  /// The top level blocks of the editor.
  late final IList<EditorBlock> blocks;

  late final Selection selection;

  Cursor get cursor => selection.end;

  EditorState.withInitialContent(String? initialContent) {
    blocks = <EditorBlock>[
      SectionBlock.withInitialContent(initialContent),
      ParagraphBlock.withInitialContent(
        initialContent: "Ein neuer Absatz.",
      ),
      BulletpointBlock.withInitialContent("Eins"),
    ].lockUnsafe;
    selection = Selection.collapsed(
      Cursor(
        blockPath: BlockPath.fromIterable(const [0]),
        piecePath: PiecePath.fromIterable(const [0]),
        offset: 0,
      ),
    );
  }

  EditorState({
    required this.blocks,
    required this.selection,
  });

  EditorState collapseSelection() => EditorState(
        blocks: blocks,
        selection: selection.collapse(),
      );

  EditorState copyWith({
    IList<EditorBlock>? blocks,
    Selection? selection,
  }) {
    return EditorState(
      blocks: blocks ?? this.blocks,
      selection: selection ?? this.selection,
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

  Piece getCursorPiece(Cursor cursor) =>
      getCursorBlock(cursor).getPieceFromPath(cursor.piecePath)!;

  Piece getCursorPreviousPiece(Cursor cursor) {
    EditorBlock cursorBlock = getCursorBlock(cursor);
    return cursorBlock
        .getPieceFromPath(cursor.piecePath.previous(cursorBlock)!)!;
  }

  Piece getCursorNextPiece(Cursor cursor) {
    EditorBlock cursorBlock = getCursorBlock(cursor);
    return cursorBlock.getPieceFromPath(cursor.piecePath.next(cursorBlock)!)!;
  }

  /// Start a selection at the current [cursor].
  EditorState beginSelection() => copyWith(
        selection: Selection(
          start: selection.end,
          end: selection.end,
        ),
      );

  /// Called before beginning a cursor movement.
  /// Handles selection state.
  EditorState beginCursorMove(bool isSelecting) {
    if (selection.isEmpty && isSelecting) {
      return beginSelection();
    } else if (!selection.isEmpty && !isSelecting) {
      return collapseSelection();
    } else {
      return this;
    }
  }

  /// Return a new cursor one character to the right from a given one.
  EditorState moveCursorRightOnce(bool isSelecting) =>
      beginCursorMove(isSelecting).replaceCursor(
        cursor.moveRightOnce(this),
      );

  /// Move the cursor left by one character.
  EditorState moveCursorLeftOnce(bool isSelecting) =>
      beginCursorMove(isSelecting).replaceCursor(
        cursor.moveLeftOnce(this),
      );

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
    // Splitting at one cursor when there are multiple cursors would invalidate the pieceIndex;
    assert(selection.isEmpty);

    if (cursor.isAtPieceStart) return this;

    PiecePath nextPiecePath = cursor.piecePath.next(getCursorBlock(cursor))!;
    return insertPieceInCursorBlock(
      cursor.piecePath,
      getCursorPiece(cursor).substring(0, cursor.offset),
    )
        .replacePieceInCursorBlock(
          nextPiecePath,
          getCursorPiece(cursor).substring(cursor.offset),
        )
        .copyWithCursor(
          piecePath: nextPiecePath,
          offset: 0,
        );
  }

  /// Insert a "hard break".
  /// Split the block at the current cursor.
  EditorState newLine() {
    if (getCursorBlock(cursor).getPieceFromPath(cursor.piecePath)
        is InlineBlock) {
      // Splitting an inline block is simply not supported.
      return this;
    }

    final splitState = splitBeforeCursor();
    assert(splitState.cursor.isAtPieceStart);
    final blockCut = splitState.replacePiecesInCursorBlock(
      (pieces) =>
          pieces.sublist(0, splitState.cursor.piecePath[0]).add(Piece.sentinel),
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
                .sublist(splitState.cursor.piecePath[0]),
          ),
        )
        .copyWithCursor(
          blockPath: newBlockPath,
          piecePath: PiecePath.fromIterable(const [0]),
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

  /// Remove the block at a given [blockPath]
  /// **including all its children**.
  EditorState removeBlock(BlockPath blockPath) {
    if (blockPath.isTopLevel) {
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

  /// Transform pieces in a given [block].
  EditorState replacePiecesInBlock(
    BlockPath block,
    IList<Piece> Function(IList<Piece>) pieceChange,
  ) =>
      replaceBlockAtPath(
        block,
        (block) => block.replacePieces(pieceChange),
      );

  /// Transform pieces in the cursor block.
  EditorState replacePiecesInCursorBlock(
    IList<Piece> Function(IList<Piece>) pieceChange,
  ) =>
      replacePiecesInBlock(cursor.blockPath, pieceChange);

  EditorState replacePieceInCursorBlock(PiecePath piecePath, Piece newPiece) {
    return replaceBlockAtPath(
      cursor.blockPath,
      (block) => block.replacePieceAtPath(piecePath, (piece) => newPiece),
    );
  }

  EditorState insertPieceInCursorBlock(PiecePath piecePath, Piece newPiece) {
    return replaceBlockAtPath(
      cursor.blockPath,
      (block) => block.insertPieceAtPath(piecePath, newPiece),
    );
  }

  EditorState replaceCursor(Cursor cursor) =>
      copyWith(selection: selection.copyWithEnd(cursor));

  EditorState copyWithCursor({
    BlockPath? blockPath,
    PiecePath? piecePath,
    int? offset,
  }) {
    return copyWith(
      selection: selection.copyWithEnd(
        cursor.copyWith(
          blockPath: blockPath,
          piecePath: piecePath,
          offset: offset,
        ),
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

    EditorBlock previousBlock = getBlockFromPath(previousBlockPath)!;
    PiecePath cursorPieceIndexAferMerge =
        PiecePath.fromIterable([previousBlock.pieces.length - 1])
            .lastLeaf(previousBlock);

    return replaceBlockAtPath(
      previousBlockPath,
      (previousBlock) => previousBlock.replacePieces(
        (pieces) => pieces.removeLast().addAll(blockToRemove.pieces),
      ),
    ).removeBlock(blockPathToRemove).copyWithCursor(
          blockPath: previousBlockPath,
          piecePath: cursorPieceIndexAferMerge,
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
    EditorState resultState = removeBlock(blockPathToReplace);
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
    if (!selection.isEmpty) {
      return deleteSelection();
    }

    EditorBlock cursorBlock = getCursorBlock(cursor);
    if (cursor.isAtPieceStart) {
      // Cursor at the start means you can simply cut the last character off the previous piece.
      if (!cursor.piecePath.isFirst) {
        // There is a previous piece
        PiecePath previousePiecePath = cursor.piecePath.previous(cursorBlock)!;
        if (getCursorPreviousPiece(cursor).text.length == 1) {
          // Piece will be empty, simply remove it.
          return replaceBlockAtPath(
            cursor.blockPath,
            (block) => block.removePiece(previousePiecePath),
          ).copyWithCursor(piecePath: previousePiecePath);
        } else {
          // Previous piece will not be empty, cut its last character.
          return replacePieceInCursorBlock(
            previousePiecePath,
            getCursorPreviousPiece(cursor).substring(0, -1),
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
        cursor.piecePath,
        getCursorPiece(cursor).substring(1),
      ).copyWithCursor(offset: 0);
    } else {
      // Cursor in the middle of a piece, split required.
      PiecePath nextPiecePath = cursor.piecePath.next(cursorBlock)!;
      return insertPieceInCursorBlock(
        cursor.piecePath,
        getCursorPiece(cursor).substring(0, cursor.offset - 1),
      )
          .replacePieceInCursorBlock(
            nextPiecePath,
            getCursorPiece(cursor).substring(cursor.offset),
          )
          .copyWithCursor(
            piecePath: nextPiecePath,
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
    ).copyWithCursor(
      piecePath: PiecePath.fromIterable(const [0]),
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

    return withSectionBlock.copyWithCursor(
      piecePath: PiecePath.fromIterable(const [0]),
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
          .removeBlock(cursor.blockPath)
          .copyWithCursor(blockPath: destinationBlockPath);
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
        .removeBlock(cursor.blockPath)
        .copyWithCursor(blockPath: destinationPath);
  }

  /// Delete a piece and adjust the selection if necessary.
  EditorState deletePiece({
    required BlockPath blockPath,
    required PiecePath piecePath,
  }) {
    Selection selection = this.selection;
    // Shift selection.start if necessary
    if (!selection.isEmpty && selection.start!.blockPath == blockPath) {
      if (selection.start!.piecePath == piecePath) {
        // Get the new selection start by putting a cursor
        // at the end of the deleted piece and moving ot right once.
        Cursor newSelectionStart = Cursor(
          blockPath: selection.start!.blockPath,
          piecePath: selection.start!.piecePath,
          offset: getBlockFromPath(blockPath)!
                  .getPieceFromPath(selection.start!.piecePath)!
                  .text
                  .length -
              1,
        ).moveRightOnce(this);
        selection = selection.copyWithStart(newSelectionStart);
      } else if (selection.start!.piecePath.compareTo(piecePath) > 0) {
        selection = selection.copyWithStart(
          selection.start!.copyWith(
            piecePath: selection.start!.piecePath
                .previous(getBlockFromPath(selection.start!.blockPath)!),
          ),
        );
      }
    }
    // Shift selection.end if necessary
    if (selection.end.blockPath == blockPath) {
      if (selection.end.piecePath == piecePath) {
        // Get the new selection start by putting a cursor
        // at the end of the deleted piece and moving ot right once.
        Cursor newSelectionEnd = Cursor(
          blockPath: selection.end.blockPath,
          piecePath: selection.end.piecePath,
          offset: getBlockFromPath(blockPath)!
                  .getPieceFromPath(selection.end.piecePath)!
                  .text
                  .length -
              1,
        ).moveRightOnce(this);
        selection = selection.copyWithEnd(newSelectionEnd);
      } else if (selection.end.piecePath.compareTo(piecePath) > 0) {
        selection = selection.copyWithEnd(
          selection.end.copyWith(
              piecePath: selection.end.piecePath
                  .previous(getBlockFromPath(selection.end.blockPath)!)),
        );
      }
    }

    return replaceBlockAtPath(
      blockPath,
      (block) => block.removePiece(piecePath),
    ).copyWith(selection: selection);
  }

  /// Replace the content of the piece at [pieceIndex] in [block]
  /// with its substring from [start] inclusive to [end] exclusive.
  /// If the piece has no content left, it is deleted and the
  /// selection is adjusted accordingly.
  EditorState substringPieceContent({
    required BlockPath blockPath,
    required PiecePath piecePath,
    required int start,
    int? end,
  }) {
    EditorBlock block = getBlockFromPath(blockPath)!;
    Piece newPiece = block.getPieceFromPath(piecePath)!.substring(start, end);
    if (newPiece.text.isEmpty) {
      return deletePiece(blockPath: blockPath, piecePath: piecePath);
    } else {
      return replaceBlockAtPath(
        blockPath,
        (block) => block.replacePieceAtPath(
          piecePath,
          (piece) => newPiece,
        ),
      );
    }
  }

  /// Delete all content in the current selection.
  EditorState deleteSelection() {
    if (selection.isEmpty) return this;

    if (selection.isInSingleBlock) {
      EditorBlock selectionBlock = getCursorBlock(selection.start!);
      Cursor selectionFirst = selection.first;
      Cursor selectionLast = selection.last;

      if (selectionFirst.piecePath ==
              selectionLast.piecePath.previous(selectionBlock) &&
          selectionFirst.offset == 0 &&
          selectionLast.offset == 0) {
        // Selection contains exactly the piece selectionFirst.pieceIndex
        // and the piece will be empty.
        return replaceBlockAtPath(
          selectionFirst.blockPath,
          (block) => block.removePiece(
            selectionFirst.piecePath,
          ),
        ).collapseSelection();
      }

      if (selectionFirst.piecePath == selectionLast.piecePath) {
        return replacePieceInCursorBlock(
          selectionFirst.piecePath,
          selectionBlock
              .getPieceFromPath(selectionFirst.piecePath)!
              .replaceRange(
                selectionFirst.offset,
                selectionLast.offset,
                "",
              ),
        ).collapseSelection().copyWithCursor(offset: selectionFirst.offset);
      }

      // Not in the same piece
      EditorState state = this;
      Cursor cursorBeforeSelection = state
          .copyWith(selection: Selection.collapsed(state.selection.first))
          .moveCursorLeftOnce(false)
          .cursor;
      // Delete in last piece up to offset
      state = state.substringPieceContent(
        blockPath: state.cursor.blockPath,
        piecePath: selectionLast.piecePath,
        start: selectionLast.offset,
      );
      // Delete all pieces between
      selectionBlock = state.getCursorBlock(selection.start!);
      Piece selectionLastPiece =
          selectionBlock.getPieceFromPath(selectionLast.piecePath)!;
      PiecePath? currPath = selectionFirst.piecePath.next(selectionBlock);
      Piece? curr =
          (currPath == null) ? null : selectionBlock.getPieceFromPath(currPath);
      while (curr != selectionLastPiece) {
        state = state.replaceBlockAtPath(
          selectionFirst.blockPath,
          (block) => block.removePiece(currPath!),
        );
        selectionBlock = state.getCursorBlock(selection.start!);
        currPath = selectionFirst.piecePath.next(selectionBlock);
        curr = (currPath == null)
            ? null
            : selectionBlock.getPieceFromPath(currPath);
      }
      // Delete in first piece after offset
      state = state.substringPieceContent(
        blockPath: cursor.blockPath,
        piecePath: selectionFirst.piecePath,
        start: 0,
        end: selectionFirst.offset,
      );
      // Move the cursor
      state = state
          .copyWith(selection: Selection.collapsed(cursorBeforeSelection))
          .moveCursorRightOnce(false);
      return state;
    }
    // Selection across multiple blocks

    Cursor selectionFirst = selection.first;
    Cursor selectionLast = selection.last;
    EditorState state = this;
    EditorBlock selectionFirstBlock =
        getBlockFromPath(selectionFirst.blockPath)!;
    // Delete first blocks content up to the end.
    if (!selectionFirst.piecePath.isLast(selectionFirstBlock)) {
      // Only if this is not the last piece already
      PiecePath? curr = selectionFirst.piecePath.next(selectionFirstBlock);
      while (curr != null && !curr.isLast(selectionFirstBlock)) {
        state = state.replaceBlockAtPath(
          selectionFirst.blockPath,
          (block) => block.removePiece(curr!),
        );
        selectionFirstBlock = state.getBlockFromPath(selectionFirst.blockPath)!;
        curr = selectionFirst.piecePath.next(selectionFirstBlock)!;
      }

      state = state.substringPieceContent(
        // Last piece is always sentinel. No need to edit content.
        blockPath: selectionFirst.blockPath,
        piecePath: selectionFirst.piecePath,
        start: 0,
        end: selectionFirst.offset,
      );
    }
    // Delete in last block up to the selection end
    state = state.substringPieceContent(
      blockPath: selectionLast.blockPath,
      piecePath: selectionLast.piecePath,
      start: selectionLast.offset,
    );
    EditorBlock selectionLastBlock =
        state.getBlockFromPath(selectionLast.blockPath)!;
    Piece selectionLastPiece =
        selectionLastBlock.getPieceFromPath(selectionLast.piecePath)!;
    PiecePath firstPiecePath =
        PiecePath.fromIterable(const [0]).firstLeaf(selectionLastBlock);
    while (selectionLastBlock.getPieceFromPath(firstPiecePath) !=
        selectionLastPiece) {
      state = state.replaceBlockAtPath(
        selectionLast.blockPath,
        (block) => block.removePiece(firstPiecePath),
      );
      selectionLastBlock = state.getBlockFromPath(selectionLast.blockPath)!;
      firstPiecePath =
          PiecePath.fromIterable(const [0]).firstLeaf(selectionLastBlock);
    }
    // Delete all blocks in between
    // Get the next block after the selection start, delete it or unwrap it, until the next block is the one on which the selection ends.
    selectionLastBlock = state.getBlockFromPath(selectionLast.blockPath)!;
    BlockPath currPath = selectionFirst.blockPath.next(state)!;
    EditorBlock curr = state.getBlockFromPath(currPath)!;
    while (curr != selectionLastBlock) {
      // Remove or unwrap
      if (curr is EditorBlockWithChildren) {
        state = state.replaceBlockWithBlocks(currPath, curr.children);
      } else {
        state = state.removeBlock(currPath);
      }
      currPath = selectionFirst.blockPath.next(state)!;
      curr = state.getBlockFromPath(currPath)!;
    }
    // Merge first and last block.
    IList<EditorBlock> replacementBlocks =
        state.getBlockFromPath(currPath)!.turnIntoParagraphBlock();
    state = state.replaceBlockWithBlocks(currPath, replacementBlocks);
    state = state.mergeWithPreviousBlock(currPath);
    state = state.collapseSelection();
    return state;
  }

  /// Insert [newContent] before the cursor.
  EditorState append(String newContent) {
    if (!selection.isEmpty) {
      return deleteSelection().append(newContent);
    }

    if (cursor.isAtPieceStart) {
      if (cursor.piecePath.isFirst) {
        // There is no previous piece, insert one.
        return insertPieceInCursorBlock(
          PiecePath.fromIterable(const [0]),
          getCursorPiece(cursor).copyWith(text: newContent),
        ).copyWithCursor(
          piecePath: PiecePath.fromIterable(const [1]),
        ); // Cursor remains where it is, but the index changes because another piece was inserted in front.
      } else {
        if (newContent == " " &&
            cursor.piecePath == PiecePath.fromIterable(const [1]) &&
            cursor.blockPath.length == 1 &&
            getCursorBlock(cursor).runtimeType == ParagraphBlock &&
            getCursorPreviousPiece(cursor).text.trim() == "#") {
          // Space after a # at the start of a [ParagraphBlock]
          // => Transform this [ParagraphBlock] into a [SectionBlock].
          return markdownShortcutH1();
        }
        if (newContent == " " &&
            cursor.piecePath == PiecePath.fromIterable(const [1]) &&
            getCursorBlock(cursor).runtimeType == ParagraphBlock &&
            getCursorPreviousPiece(cursor).text.trim() == "-") {
          // Space after a - at the start of a [ParagraphBlock]
          // => Transform this [ParagraphBlock] into a [BulletpointBlock].
          return markdownShortcutBulletpoint();
        }
        // Append to the previous piece.
        return replacePieceInCursorBlock(
          cursor.piecePath.previous(getCursorBlock(cursor))!,
          getCursorPreviousPiece(cursor).append(newContent),
        );
      }
    } else {
      // Cursor is not at the start, piece must be split.
      // Insert first half.
      PiecePath nextPiecePath = cursor.piecePath.next(getCursorBlock(cursor))!;
      return insertPieceInCursorBlock(
        cursor.piecePath,
        getCursorPiece(cursor).substring(0, cursor.offset).append(newContent),
      )
          .replacePieceInCursorBlock(
            // Append to the second half.
            nextPiecePath,
            getCursorPiece(cursor).substring(cursor.offset),
          ) // Cursor remains where it is, but the index changes because another piece was inserted in front.
          .copyWithCursor(
            piecePath: nextPiecePath,
            offset: 0,
          );
    }
  }
}
