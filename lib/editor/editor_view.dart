import 'package:memex_ui/editor/block.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/cursor.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

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
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            if (event.isShiftPressed) {
              setState(() {
                widget.editor.unindent();
              });
            } else {
              setState(() {
                widget.editor.indent();
              });
              return;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (event.isShiftPressed) {
              setState(() {
                widget.editor.append("\n");
              });
              return;
            } else {
              setState(() {
                widget.editor.newLine();
              });
              return;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            setState(() {
              widget.editor.deleteBackwards();
            });
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyZ &&
              event.isControlPressed) {
            if (event.isShiftPressed) {
              setState(() {
                widget.editor.redo();
              });
              return;
            } else {
              setState(() {
                widget.editor.undo();
              });
              return;
            }
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
        child: ListView.builder(
          itemCount: widget.editor.state.blocks.length,
          itemBuilder: (context, index) {
            EditorBlock block = widget.editor.state.blocks[index];
            Cursor? cursor;
            if (index == widget.editor.state.cursor.blockPath[0]) {
              cursor = widget.editor.state.cursor;
            }
            return block.build(context, cursor, BlockPath.constant([index]));
          },
        ),
      ),
    );
  }
}
