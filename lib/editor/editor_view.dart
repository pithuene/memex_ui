import 'dart:io';
import 'package:flutter/rendering.dart';
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
  void didUpdateWidget(covariant EditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.editor.onRebuild.stream.listen((event) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => focusNode.requestFocus(),
      opaque: false,
      child: RawKeyboardListener(
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
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 750),
                    alignment: Alignment.topLeft,
                    child: PaddedBlock(
                      path: BlockPath.fromIterable([index]),
                      block: widget.editor.state.blocks[index],
                      editor: widget.editor,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
