import 'package:flutter/widgets.dart';
export 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'editor.dart';

/// Execute [body] in a loop as long as true is returned.
/// An assertion is triggered if the loop is executed more
/// than [limit] times.
/// Useful to catch infinite loops early.
void boundedWhile(int limit, bool Function() body) {
  int loopLimit = limit;
  bool keepGoing = true;
  while (keepGoing) {
    assert(
      loopLimit > 0,
      "Bounded while loop exceeded its limit of $limit executions.",
    );
    keepGoing = body();
    loopLimit--;
  }
}

/// Every [EditorNode] has access to its context
/// in the editor tree through this class.
/* TODO Remove
class EditorContext {
  /// The [NodePath] to this [EditorNode].
  NodePath path;

  IList<EditorNode> ancestors;

  EditorContext({
    required this.path,
    required this.ancestors,
  });

  EditorContext.root()
      : path = NodePath([]),
        ancestors = <EditorNode>[].lockUnsafe;

  /// Generate this contexts child context.
  EditorContext child(int childIndex, EditorNode child) => EditorContext(
        path: path.child(childIndex),
        ancestors: ancestors.add(child),
      );
}*/

class EditorElement extends ComponentElement {
  EditorElement(EditorNode super.widget);

  NodePath? path;
  EditorElement? parent;
  List<EditorElement> children = [];

  /*EditorElement? get parent {
    EditorElement? target;
    visitAncestorElements((element) {
      if (element is EditorElement) {
        target = element;
        return false;
      }
      return true;
    });
    return target;
  }*/

  void setupEditorTreeContext() {
    assert(
      mounted,
      "Can't set EditorElement context before element is mounted.",
    );
    // Set [parent].
    parent = null;
    visitAncestorElements((element) {
      if (element is EditorElement) {
        parent = element;
        return false;
      }
      return true;
    });

    // Set [children] of [parent].
    children = [];
    if (parent != null) {
      parent!.children.add(this);
    }

    // Set [path].
    if (parent != null) {
      assert(
        (parent!.widget as EditorInnerNode).children.length < 64,
        "Retrieving the index using indexOf will not scale well.",
      );
      int indexInParent = (parent!.widget as EditorInnerNode)
          .children
          .indexOf(widget as EditorNode);
      // TODO: Is indexInParent always equal to parent.children.length before the children.add?
      path = parent!.path!.child(indexInParent);
    } else {
      path = NodePath.root();
    }
    assert(path != null);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    setupEditorTreeContext();
  }

  @override
  Widget build() {
    return (widget as EditorNode).build(this);
  }

  @override
  void update(EditorNode newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    setupEditorTreeContext();
    rebuild(force: true);
  }

  Editor? get editor => findAncestorWidgetOfExactType<Editor>();

  EditorElement? get lastLeaf {
    if (children.isEmpty) return null;
    EditorElement curr = children.last;
    while (curr.children.isNotEmpty) {
      curr = curr.children.last;
    }
    return curr;
  }

  /// Replace this [EditorNode] by a given [newNode].
  void replaceBy(EditorNode newNode) => editor!.replaceAt(path!, newNode);
}

abstract class EditorNode extends Widget {
  /*TODO
  T? findParentOfType<T extends EditorInnerNode>() {
    EditorInnerNode? target = parent;
    boundedWhile(32, () {
      if (target == null) return false;
      if (target.runtimeType == T) return false;
      target = target!.parent;
      return true;
    });
    return target as T?;
  }*/

  const EditorNode({super.key});

  @override
  EditorElement createElement() => EditorElement(this);

  @protected
  Widget build(EditorElement el);

  EditorNode copyWith({Key? key});
}

abstract class EditorInnerNode extends EditorNode {
  final IList<EditorNode> children;

  /* TODO Remove?
  EditorNode get lastLeaf {
    if (children.last is EditorInnerNode &&
        (children.last as EditorInnerNode).children.isNotEmpty) {
      return (children.last as EditorInnerNode).lastLeaf;
    } else {
      return children.last;
    }
  }*/

  const EditorInnerNode({
    super.key,
    required this.children,
  });

  @override
  EditorInnerNode copyWith({
    Key? key,
    IList<EditorNode>? children,
  });
}
