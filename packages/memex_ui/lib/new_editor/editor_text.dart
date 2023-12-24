import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/color.dart';
import 'package:memex_ui/typography.dart';

import 'node_path.dart';
import 'editor_widget.dart';
import 'editor.dart';

/// Non marked up plain text
class EditorText extends EditorNode {
  final FocusNode focusNode;
  final TextEditingValue value;
  final TextEditingController _controller;

  EditorText(
    this.value, {
    super.key,
    FocusNode? focusNode,
  })  : focusNode = focusNode ?? FocusNode(),
        _controller = TextEditingController.fromValue(value);

  @override
  EditorText copyWith({
    TextEditingValue? value,
    FocusNode? focusNode,
    Key? key,
  }) =>
      EditorText(
        value ?? this.value,
        focusNode: focusNode ?? this.focusNode,
        key: key ?? this.key,
      );

  @override
  Widget build(EditorElement el) => Container(
        color: false ? CupertinoColors.activeBlue : const Color(0x00000000),
        child: EditableText(
          enableInteractiveSelection: true,
          controller: _controller,
          focusNode: focusNode,
          maxLines: null,
          style: MemexTypography.body.copyWith(overflow: TextOverflow.visible),
          selectionColor: MemexColor.selection,
          cursorColor: MemexColor.text,
          backgroundCursorColor: CupertinoColors.inactiveGray,
          onChanged: (_) => el.replaceBy(copyWith(value: _controller.value)),
        ),

        /*KeyboardListener(
          focusNode: focusNode,
          child: GestureDetector(
            onTap: () => focusNode.requestFocus(),
            child: Text(
              content,
              key: key,
            ),
          ),
          onKeyEvent: (event) {
            if (event.character != null) {
              append(event.character!);
            }
          },
        ),*/
      );

  /*void append(String newContent) {
    print("Appending $newContent");
    replaceBy(copyWith(content: content + newContent));
  }*/
}
