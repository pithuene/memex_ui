import 'package:memex_ui/editor/block.dart';

import './editor.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditorView extends StatefulWidget {
  const EditorView({
    super.key,
    required this.editor,
  });
  final Editor editor;

  @override
  State<StatefulWidget> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    List<Widget> blockWidgets = [];
    for (EditorBlock block in widget.editor.blocks) {
      blockWidgets.add(block.build(context));
      blockWidgets.add(Container(height: 15));
    }

    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (event) {
        if (event.runtimeType == KeyDownEvent ||
            event.runtimeType == KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(() {
              widget.editor.cursor =
                  widget.editor.moveRightOnce(widget.editor.cursor);
            });
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(() {
              widget.editor.cursor =
                  widget.editor.moveLeftOnce(widget.editor.cursor);
            });
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            setState(() {
              widget.editor.append("\n");
            });
            return;
          }
          if (event.character != null) {
            setState(() {
              widget.editor.append(event.character ?? "?");
            });
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: blockWidgets,
        ),
      ),
    );
  }
}
