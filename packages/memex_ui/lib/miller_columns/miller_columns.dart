import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memex_ui/memex_ui.dart';

typedef Path<Key> = IList<Key>;

class NodeAndKey<Key, Node> {
  Node node;

  /// The last part of the path to this node.
  Key key;
  NodeAndKey(this.node, this.key);
}

class MillerColumns<Key, Node> extends StatefulWidget {
  /// Hook to extend the keyboard controls.
  final void Function(RawKeyEvent, MillerColumnsState<Key, Node>)? onKey;

  /// Get the children of a given parent node.
  /// If the node is a leaf, return null.
  final Future<Iterable<NodeAndKey<Key, Node>>?> Function(Node) getChildren;

  /// Builder to display a given node.
  final Widget Function(BuildContext, Node) rowBuilder;

  /// Called when a leaf is selected.
  final void Function(Node)? onSelect;

  /// The number of columns that are shown.
  /// Does not include the right most preview column.
  final int columnCount;

  /// The path from the [rootNode] which is initially shown.
  final Path<Key> initialPath;

  /// The node at path [].
  final Node rootNode;

  const MillerColumns({
    super.key,
    this.onKey,
    this.onSelect,
    this.columnCount = 5,
    this.initialPath = const IListConst([]),
    required this.rootNode,
    required this.getChildren,
    required this.rowBuilder,
    //required this.toKey,
  });

  @override
  State<StatefulWidget> createState() => MillerColumnsState<Key, Node>();
}

class GraphNode<Key, Node> {
  Path<Key> path;
  Node node;

  IList<Path<Key>>? children;
  int selectedChildIndex = 0;

  /// Whether the node is a leaf.
  /// Returns null if the children have not been loaded,
  /// and it is therefore not clear whether the node is a leaf.
  bool? get isLeaf => childrenLoaded ? children == null : null;

  bool childrenLoaded;

  Path<Key>? get selectedChildPath =>
      childrenLoaded ? children![selectedChildIndex] : null;

  GraphNode(this.path, this.node) : childrenLoaded = false;

  GraphNode.withChildren(this.path, this.node, this.children)
      : childrenLoaded = true;

  @override
  String toString() {
    return "[GraphNode $path $children children]";
  }
}

class MillerColumnsState<Key, Node> extends State<MillerColumns<Key, Node>> {
  final FocusNode focusNode = FocusNode();

  Path<Key> path = <Key>[].lockUnsafe;

  IMap<Path<Key>, GraphNode<Key, Node>> graph =
      <Path<Key>, GraphNode<Key, Node>>{}.lockUnsafe;

  /// Functions which return which path the datasources are showing.
  List<Path<Key>? Function()> tableDatasourcesShownPaths = [];
  List<TableDatasource<Node>> tableDatasources = [];

  @override
  void initState() {
    super.initState();
    initDatasources();
    initColumns();
    focusNode.requestFocus();
  }

  Future<void> initDatasources() async {
    final List<ColumnDefinition<Node>> colDefs = [
      ColumnDefinition<Node>(
        label: "Nodes",
        cellBuilder: widget.rowBuilder,
      )
    ];

    for (int i = widget.columnCount - 1; i >= 0; i--) {
      tableDatasourcesShownPaths.add(() {
        if (path.length - i < 0) {
          return null;
        }
        return path.sublist(0, path.length - i);
      });
      tableDatasources.add(
        TableDatasource(
          colDefs: colDefs,
          getRowCount: () {
            if (path.length - i < 0) {
              return 0;
            }
            Path<Key> shownPath = path.sublist(0, path.length - i);
            if (!graph.containsKey(shownPath)) {
              print("$shownPath not in graph");
              return 0;
            }
            return graph[shownPath]!.children?.length ?? 0;
          },
          getRowValue: (index) {
            Path<Key> shownPath = path.sublist(0, path.length - i);
            Path<Key> childPath = graph[shownPath]!.children![index];
            return toTableValue(childPath);
          },
        ),
      );
    }
    setState(() {});
  }

  /// Get a [TableValue] for a given node path.
  TableValue<Node> toTableValue(Path<Key> path) => TableValue<Node>(
        key: ValueKey(path),
        value: graph[path]!.node,
      );

  void refreshColumns() {
    int i = 0;
    for (TableDatasource<Node> datasource in tableDatasources) {
      Path<Key>? shownPath = tableDatasourcesShownPaths[i]();
      datasource.dataChanged();
      if (shownPath != null) {
        datasource.selectIndex(graph[shownPath]!.selectedChildIndex);
      }
      i++;
    }
  }

  Future<void> fetchNodeChildren(GraphNode<Key, Node> parentNode) async {
    var children = await widget.getChildren(parentNode.node);
    if (children == null) {
      // Node is leaf
      parentNode.children = null;
      parentNode.childrenLoaded = true;
      return;
    }

    for (NodeAndKey<Key, Node> child in children) {
      Path<Key> childPath = parentNode.path.add(child.key);
      graph = graph.add(
        childPath,
        GraphNode(childPath, child.node),
      );
    }
    parentNode.children = children
        .map(
          (child) => parentNode.path.add(child.key),
        )
        .toIList();
    parentNode.childrenLoaded = true;
  }

  Future<void> initColumns() async {
    path = widget.initialPath;

    GraphNode<Key, Node> root = GraphNode(<Key>[].lockUnsafe, widget.rootNode);
    graph = graph.add(<Key>[].lockUnsafe, root);

    await fetchNodeChildren(root);

    GraphNode<Key, Node> current = root;
    for (int i = 1; i < path.length + 1; i++) {
      assert(current.childrenLoaded);
      Path<Key> nextPath = path.sublist(0, i);
      current.selectedChildIndex = current.children!.indexOf(nextPath);
      current = graph[nextPath]!;
      await fetchNodeChildren(current);
    }

    refreshColumns();
  }

  void moveSelectionDown() {
    tableDatasources.last.moveSelectionDown();
    if (graph[path]!.selectedChildIndex <
        (graph[path]!.children?.length ?? 0) - 1) {
      graph[path]!.selectedChildIndex++;
      // TODO: Refresh preview column
    }
  }

  void moveSelectionUp() {
    tableDatasources.last.moveSelectionUp();
    if (graph[path]!.selectedChildIndex > 0) {
      graph[path]!.selectedChildIndex--;
      // TODO: Refresh preview column
    }
  }

  Future<void> moveIntoSelectedChild() async {
    Path<Key> childPath = graph[path]!.selectedChildPath!;
    GraphNode<Key, Node> child = graph[childPath]!;
    if (!child.childrenLoaded) {
      print("Loading children");
      await fetchNodeChildren(child);
    }
    if (child.isLeaf!) {
      if (widget.onSelect != null) widget.onSelect!(child.node);
      return;
    }
    path = childPath;
    refreshColumns();
    tableDatasources.last.selectIndex(child.selectedChildIndex);
  }

  void moveToParent() {
    if (path.isEmpty) return;
    path = path.removeLast();
    refreshColumns();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: focusNode,
      onKey: (event) async {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyH) {
            moveToParent();
            return;
          } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
            await moveIntoSelectedChild();
            return;
          } else if (event.logicalKey == LogicalKeyboardKey.keyJ) {
            moveSelectionDown();
            return;
          } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
            moveSelectionUp();
            return;
          }
        }
        if (widget.onKey != null) widget.onKey!(event, this);
      },
      child: Row(
        children: [
          ...tableDatasources.mapIndexedAndLast(
            (_, datasource, isLast) => Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          right: BorderSide(color: CupertinoColors.separator),
                        ),
                ),
                child: TableView<Node>(
                  rowHeight: 24,
                  dataSource: datasource,
                  showHeader: false,
                  fullWidthHighlight: true,
                  showEvenRowHighlight: false,
                  isActive: Prop(isLast),
                ),
              ),
            ),
          ),
          // TODO: Preview column
        ],
      ),
    );
  }
}
