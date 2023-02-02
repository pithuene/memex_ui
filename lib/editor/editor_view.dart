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
    for (EditorBlock block in widget.editor.state.blocks) {
      blockWidgets.add(block.build(context, widget.editor.state.cursor));
      blockWidgets.add(Container(height: 15));
    }

    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (event) {
        if (event.runtimeType == RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(() {
              widget.editor.moveCursorRightOnce();
            });
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(() {
              widget.editor.moveCursorLeftOnce();
            });
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (event.isShiftPressed) {
              setState(() {
                widget.editor.append("\n");
              });
              return;
            } else {
              setState(() {});
              print("New Paragraph");
              return;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            setState(() {
              widget.editor.deleteBackwards();
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
