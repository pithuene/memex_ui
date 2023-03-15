import 'dart:async';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/blocks/editor_block_with_children.dart';
import 'package:memex_ui/editor/keymaps/keymap.dart';
import 'package:memex_ui/editor/keymaps/keymap_standard.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:flutter/material.dart';

typedef LinkHandler = void Function(String);

class EditorView extends StatefulWidget {
  const EditorView({
    super.key,
    required this.editor,
    this.scrollController,
    this.keymap = const KeymapStandard(),
    this.linkHandler,
    this.header,
  });
  final Editor editor;
  final ScrollController? scrollController;
  final Keymap keymap;
  final LinkHandler? linkHandler;

  /// A widget which is shown above the editor content but inside the scrollable area.
  /// Can be used to display a document title.
  final Widget? header;

  @override
  State<StatefulWidget> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  final FocusNode focusNode = FocusNode(descendantsAreTraversable: false);

  @override
  void initState() {
    super.initState();
    setupEditorStreams();
  }

  @override
  void didUpdateWidget(covariant EditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    setupEditorStreams();
  }

  StreamSubscription<void>? rebuildStreamSubscription;
  StreamSubscription<String>? handleLinkStreamSubscription;

  void setupEditorStreams() {
    if (rebuildStreamSubscription != null) rebuildStreamSubscription!.cancel();
    rebuildStreamSubscription =
        widget.editor.onRebuild.stream.listen((event) => setState(() {}));
    if (handleLinkStreamSubscription != null) {
      handleLinkStreamSubscription!.cancel();
    }
    handleLinkStreamSubscription =
        widget.editor.onHandleLink.stream.listen((target) {
      if (widget.linkHandler != null) {
        widget.linkHandler!(target);
      }
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
          // TODO: This optimization can only be used when there is a way to rebuild single blocks. Currently, cursor movement would not rebuild block content, which breaks the change in view when a block or piece includes the caret.
          //if (needRebuild) setState(() {});
          setState(() {});
        },
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: widget.editor.state.blocks.length +
                (widget.header != null ? 1 : 0),
            itemBuilder: (context, index) {
              Widget child;
              if (widget.header != null && index == 0) {
                child = widget.header!;
              } else {
                child = PaddedBlock(
                  path: BlockPath.fromIterable([index - 1]),
                  block: widget.editor.state.blocks[index - 1],
                  editor: widget.editor,
                );
              }
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 750),
                  alignment: Alignment.topLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: child,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
