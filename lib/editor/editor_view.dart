import 'dart:io';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/blocks/editor_block.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditorView extends StatefulWidget {
  const EditorView({
    super.key,
    required this.editor,
    required this.openFile,
    required this.saveFile,
  });
  final Editor editor;
  final Future<File> Function() openFile;
  final Future<void> Function(String content) saveFile;

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
            if (event.isControlPressed) {
              setState(() {
                widget.editor.moveCursorRightOneWord(event.isShiftPressed);
              });
              return;
            } else {
              setState(() {
                widget.editor.moveCursorRightOnce(event.isShiftPressed);
              });
              return;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (event.isControlPressed) {
              setState(() {
                widget.editor.moveCursorLeftOneWord(event.isShiftPressed);
              });
              return;
            } else {
              setState(() {
                widget.editor.moveCursorLeftOnce(event.isShiftPressed);
              });
              return;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              widget.editor.moveCursorDown(event.isShiftPressed);
            });
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              widget.editor.moveCursorUp(event.isShiftPressed);
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
          if (event.logicalKey == LogicalKeyboardKey.keyS &&
              event.isControlPressed) {
            serializeEditorState(widget.editor.state).then((markdown) {
              widget.saveFile(markdown);
            }).onError((error, stackTrace) {
              print(error);
              return null;
            });
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyO &&
              event.isControlPressed) {
            widget.openFile().then((selectedFile) {
              parseMarkdown(selectedFile).then((newState) {
                setState(() {
                  widget.editor.state = newState;
                });
              });
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
        child: ListView.builder(
          itemCount: widget.editor.state.blocks.length,
          itemBuilder: (context, index) {
            EditorBlock block = widget.editor.state.blocks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: block.build(
                context: context,
                selection: widget.editor.state.selection,
                path: BlockPath.fromIterable([index]),
              ),
            );
          },
        ),
      ),
    );
  }
}
