import 'package:memex_ui/memex_ui.dart';

class NodePath {
  final IList<int> _path;
  NodePath(Iterable<int> path) : _path = path.toIList();
  NodePath.root() : _path = const <int>[].lockUnsafe;
  NodePath._(this._path);

  NodePath child(int childIndex) => NodePath._(_path.add(childIndex));
  NodePath withoutFirst() => NodePath._(_path.removeAt(0));

  bool get isEmpty => _path.isEmpty;
  int get first => _path.first;

  @override
  String toString() => _path.toString();

  @override
  bool operator ==(Object other) => other is NodePath && other._path == _path;

  @override
  int get hashCode => _path.hashCode;
}
