import 'dart:io';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/blocks/editor_block_with_children.dart';
import 'package:memex_ui/editor/keymaps/keymap.dart';
import 'package:memex_ui/editor/keymaps/keymap_standard.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:flutter/material.dart';

class EditorView extends StatefulWidget {
  const EditorView({
    super.key,
    required this.editor,
    this.scrollController,
    this.keymap = const KeymapStandard(),
  });
  final Editor editor;
  final ScrollController? scrollController;
  final Keymap keymap;

  @override
  State<StatefulWidget> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  final FocusNode focusNode = FocusNode(descendantsAreTraversable: false);

  @override
  void initState() {
    super.initState();
    widget.editor.onRebuild.stream.listen((event) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: focusNode,
      onKey: (event) {
        if (!focusNode.hasPrimaryFocus) return;
        bool needRebuild = widget.keymap.handle(widget.editor, event);
        if (needRebuild) setState(() {});
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
                width: 750,
                child: PaddedBlock(
                  path: BlockPath.fromIterable([index]),
                  block: widget.editor.state.blocks[index],
                  editor: widget.editor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
