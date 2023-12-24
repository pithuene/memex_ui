import 'package:flutter/material.dart';
import 'package:memex_ui/memex_ui.dart';

import 'editor_node.dart';
import 'editor_widget.dart';
import 'node_path.dart';

class EditorDocument extends EditorInnerNode {
  final FocusNode focusNode;

  EditorDocument({
    required super.children,
    super.key,
    FocusNode? focusNode,
  }) : focusNode = focusNode ?? FocusNode();

  @override
  EditorDocument copyWith({
    Key? key,
    FocusNode? focusNode,
    IList<EditorNode>? children,
  }) =>
      EditorDocument(
        key: key ?? this.key,
        focusNode: focusNode ?? this.focusNode,
        children: children ?? this.children,
      );

  @override
  Widget build(EditorElement el) => SelectableRegion(
        focusNode: focusNode,
        selectionControls: desktopTextSelectionControls,
        child: ListView.builder(
          itemCount: children.length,
          itemBuilder: (_, index) => children[index],
        ),
      );
}
