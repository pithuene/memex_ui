import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:memex_ui/editor/blocks/editor_block.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'dart:math';

/// Each block contains a tree of pieces making up its content.
/// Text is only stored in the leaf pieces.
@immutable
class PiecePath {
  const PiecePath(this._path);
  PiecePath.fromIterable(Iterable<int> path) : _path = path.toIList();
  final IList<int> _path;

  int get length => _path.length;
  int get first => _path.first;
  int get last => _path.last;
  int get single => _path.single;
  bool get isEmpty => _path.isEmpty;
  bool get isNotEmpty => _path.isNotEmpty;

  int operator [](int index) => _path[index];

  @override
  bool operator ==(Object other) => (other is PiecePath)
      ? (identical(other, this) || other._path.deepEquals(_path))
      : false;

  @override
  String toString() => _path.toString();

  int compareTo(PiecePath other) {
    int sharedLength = min(length, other.length);
    for (int i = 0; i < sharedLength; i++) {
      if (this[i] < other[i]) {
        return -1;
      } else if (this[i] > other[i]) {
        return 1;
      }
    }
    // The shared part is the same.
    if (length == other.length) {
      return 0;
    }
    // The shorter path is the smaller one.
    return length.compareTo(other.length);
  }

  PiecePath add(int item) => PiecePath(_path.add(item));
  PiecePath replace(int index, int value) =>
      PiecePath(_path.replace(index, value));
  PiecePath sublist(int start, [int? end]) =>
      PiecePath(_path.sublist(start, end));

  PiecePath nextNeighbor() => replace(length - 1, last + 1);
  PiecePath previousNeighbor() => replace(length - 1, last - 1);

  /// Path to this pieces first child.
  PiecePath firstChild() => PiecePath(_path.add(0));

  /// Path to this pieces last child
  PiecePath lastChild(EditorBlock block) => PiecePath(_path
      .add((block.getPieceFromPath(this) as InlineBlock).children.length - 1));

  /// Path to this pieces parent.
  PiecePath parent() => PiecePath(_path.removeLast());

  /// Whether this piece has no parent.
  bool get isTopLevel => _path.length == 1;

  /// Whether this piece is the first in the block.
  bool get isFirst {
    for (int i = 0; i < length; i++) {
      if (this[i] != 0) return false;
    }
    return true;
  }

  /// Whether this block has any previous neighbor
  bool get isFirstChild => last <= 0;

  /* Operations which require the block: */

  /// Return the first leaf in this piece and its children.
  PiecePath firstLeaf(EditorBlock block) {
    PiecePath currPath = this;
    while (block.getPieceFromPath(currPath)! is InlineBlock) {
      currPath = currPath.firstChild();
    }
    return currPath;
  }

  /// Return the last leaf in this piece and its children.
  PiecePath lastLeaf(EditorBlock block) {
    PiecePath currPath = this;
    Piece curr = block.getPieceFromPath(currPath)!;
    while (curr is InlineBlock) {
      currPath = currPath.lastChild(block);
      curr = block.getPieceFromPath(currPath)!;
    }
    return currPath;
  }

  /// Whether there is no next piece.
  bool isLast(EditorBlock block) {
    PiecePath? nextPiecePath = next(block);
    return nextPiecePath == null;
  }

  /// Whether this piece is inside an inline block.
  bool isInInlineBlock(EditorBlock block) {
    return !isTopLevel;
  }

  /// Find the piece path to the next leaf piece for a given leaf piece.
  /// Returns null if this is the last piece.
  PiecePath? next(EditorBlock block) {
    Piece currentPiece = block.getPieceFromPath(this)!;
    assert(currentPiece is! InlineBlock);

    PiecePath curr = this;
    while (curr.isNotEmpty &&
        block.getPieceFromPath(curr.nextNeighbor()) == null) {
      curr = curr.parent();
    }
    if (curr.isEmpty) {
      return null;
    }
    return curr.nextNeighbor().firstLeaf(block);
  }

  /// Find the path to the previous piece.
  /// Returns null if this is the first piece.
  PiecePath? previous(EditorBlock block) {
    PiecePath curr = this;
    while (curr.isNotEmpty && curr.isFirstChild) {
      curr = curr.parent();
    }
    if (curr.isEmpty) {
      return null;
    }
    return curr.previousNeighbor().lastLeaf(block);
  }
}
