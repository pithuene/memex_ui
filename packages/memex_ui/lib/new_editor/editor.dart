import 'package:memex_ui/memex_ui.dart';

import 'node_path.dart';
import 'editor_widget.dart';
export 'editor_node.dart';
import 'editor_document.dart';
export 'editor_document.dart';
export 'editor_widget.dart';
export 'editor_text.dart';
export 'editor_paragraph.dart';
export 'editor_selection.dart';
export 'node_path.dart';

class _EditorContent extends ReactiveWidget {
  const _EditorContent();

  @override
  Widget build(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Editor>()!.document.value;
}

class Editor extends InheritedWidget {
  final Prop<EditorDocument> document;

  // TODO: There should propably be some sort of transaction mechanism.

  Editor({
    Key? key,
    required EditorDocument document,
  })  : document = Prop(document),
        super(
          key: key,
          child: const _EditorContent(),
        );

  @override
  bool updateShouldNotify(Editor oldWidget) => false;

  /*static Editor of(BuildContext context) {
    final Editor? inherited =
        context.dependOnInheritedWidgetOfExactType<Editor>();
    assert(inherited != null);
    return inherited!;
  }*/

  void replaceAt(NodePath path, EditorNode newNode) {
    EditorNode replaceAtRec(
      EditorNode root,
      NodePath path,
      EditorNode newElement,
    ) {
      if (path.isEmpty) {
        return newElement;
      }
      assert(root is EditorInnerNode);
      return (root as EditorInnerNode).copyWith(
        children: root.children.replace(
          path.first,
          replaceAtRec(
            root.children[path.first],
            path.withoutFirst(),
            newElement,
          ),
        ),
      );
    }

    EditorDocument newDoc = replaceAtRec(
      document.value,
      path,
      newNode,
    ) as EditorDocument;
    print(newDoc.toStringDeep());
    document.value = newDoc;
  }
}
