import 'dart:io';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/blocks/editor_block.dart';
import 'package:memex_ui/editor/blocks/editor_block_with_children.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditorView extends StatefulWidget {
  const EditorView({
    super.key,
    required this.editor,
    required this.openFile,
    required this.saveFile,
    this.scrollController,
  });
  final Editor editor;
  final Future<File> Function() openFile;
  final Future<void> Function(String content) saveFile;
  final ScrollController? scrollController;

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
                widget.editor.lineBreakSoft();
              });
              return;
            } else {
              setState(() {
                widget.editor.lineBreakHard();
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
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        controller: widget.scrollController,
        itemCount: widget.editor.state.blocks.length,
        itemBuilder: (context, index) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 600,
                child: PaddedBlock(
                  path: BlockPath.fromIterable([index]),
                  block: widget.editor.state.blocks[index],
                  state: widget.editor.state,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
