import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:memex_ui/editor/block.dart';
import 'package:memex_ui/memex_ui.dart';

@immutable
class BlockPath {
  const BlockPath(this._path);
  BlockPath.constant(Iterable<int> path) : _path = path.toIList();
  final IList<int> _path;

  int get length => _path.length;
  int get first => _path.first;
  int get last => _path.last;
  int get single => _path.single;
  bool get isEmpty => _path.isEmpty;
  bool get isNotEmpty => _path.isNotEmpty;

  int operator [](int index) => _path[index];

  BlockPath add(int item) => BlockPath(_path.add(item));
  BlockPath replace(int index, int value) =>
      BlockPath(_path.replace(index, value));
  BlockPath sublist(int start, [int? end]) =>
      BlockPath(_path.sublist(start, end));

  BlockPath nextNeighbor() => replace(length - 1, last + 1);
  BlockPath previousNeighbor() => replace(length - 1, last - 1);

  /// Path to this blocks first child.
  BlockPath firstChild() => BlockPath(_path.add(0));

  /// Path to this blocks parent.
  BlockPath parent() => BlockPath(_path.removeLast());

  /// Whether this block has no parent.
  bool get isTopLevel => _path.length == 1;

  /// Whether this block is the first in the editor.
  bool get isFirst => isTopLevel && _path[0] == 0;

  /// Whether this block has any previous neighbor
  bool get isFirstChild => last <= 0;

  /* Operations which require EditorState: */

  /// Find the block path to the next block.
  /// Returns null if this is the last block.
  BlockPath? next(EditorState state) {
    EditorBlock currentBlock = state.getBlockFromPath(this)!;
    if (currentBlock is EditorBlockWithChildren && currentBlock.hasChildren) {
      return firstChild();
    } else {
      BlockPath nextPath = nextNeighbor();
      EditorBlock? next = state.getBlockFromPath(nextPath);
      while (next == null && nextPath.length > 1) {
        nextPath = nextPath.parent().nextNeighbor();
        next = state.getBlockFromPath(nextPath);
      }
      if (next == null) return null;
      return nextPath;
    }
  }

  /// Find the block path to the previous block.
  /// Returns null if this is the first block.
  BlockPath? previous(EditorState state) {
    if (isFirst) {
      return null;
    }
    if (isFirstChild) {
      return parent();
    } else {
      BlockPath previousBlockPath = previousNeighbor();
      return previousBlockPath.lastChild(state);
    }
  }

  BlockPath lastChild(EditorState state) {
    BlockPath result = this;
    EditorBlock currentBlock = state.getBlockFromPath(this)!;
    while (
        currentBlock is EditorBlockWithChildren && currentBlock.hasChildren) {
      result = result.add(currentBlock.lastChildIndex);
      currentBlock = state.getBlockFromPath(result)!;
    }
    return result;
  }
}
