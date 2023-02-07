import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';

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
  BlockPath removeLast() => BlockPath(_path.removeLast());
  BlockPath sublist(int start, [int? end]) =>
      BlockPath(_path.sublist(start, end));

  BlockPath nextNeighbor() => replace(length - 1, last + 1);
  BlockPath previousNeighbor() => replace(length - 1, last - 1);
}
