import 'package:memex_ui/memex_ui.dart';
import 'editor.dart';
import 'node_path.dart';
import 'editor_node.dart';

class Cursor {
  final NodePath node;
  final int offset;
  const Cursor(this.node, this.offset);
}

class Selection {
  final Cursor? start;
  final Cursor end;
  const Selection(this.start, this.end);
  const Selection.collapsed(this.end) : start = null;
  bool get isCollapsed => start != null;
}

/// Manages selection information of its children.
class EditorSelection extends EditorInnerNode {
  final Selection selection;
  const EditorSelection({
    required super.children,
    super.key,
    required this.selection,
  });

  @override
  EditorInnerNode copyWith({
    Key? key,
    IList<EditorNode>? children,
    Selection? selection,
  }) =>
      EditorSelection(
        children: children ?? this.children,
        key: key ?? this.key,
        selection: selection ?? this.selection,
      );

  @override
  Widget build(EditorElement el) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.unlockView,
      );
}
