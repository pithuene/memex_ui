import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/color.dart';
import 'package:memex_ui/typography.dart';

import 'node_path.dart';
import 'editor_widget.dart';
import 'editor.dart';

abstract class EditorSpan {
  InlineSpan toSpan();

  /// Override [build] to show an inline widget or
  /// override [toSpan] to show a span of text.
  Widget build(EditorElement el) =>
      throw UnsupportedError("Use EditorSpans inside an EditorParagraph.");
}

class EditorSpanBlue extends EditorInnerNode with EditorSpan {
  EditorSpanBlue({
    super.key,
    required super.children,
  });

  @override
  EditorInnerNode copyWith({
    Key? key,
    IList<EditorNode>? children,
  }) =>
      EditorSpanBlue(
        children: children ?? this.children,
        key: key ?? this.key,
      );

  @override
  InlineSpan toSpan() => TextSpan(
        style: const TextStyle(color: Color(0xFF0000FF)),
        children:
            children.map((child) => (child as EditorSpan).toSpan()).toList(),
      );
}

abstract class EditorSpanText extends EditorNode with EditorSpan {
  final String content;
  EditorSpanText(this.content, {super.key});

  @override
  EditorNode copyWith({
    Key? key,
    String? content,
  });

  void append(EditorElement el, String newContent) {
    print("Appending to ${el.path}");
    el.replaceBy(copyWith(content: content + newContent));
  }
}

class EditorSpanPlain extends EditorSpanText {
  EditorSpanPlain(super.content, {super.key});

  @override
  EditorNode copyWith({
    Key? key,
    String? content,
  }) =>
      EditorSpanPlain(
        content ?? this.content,
        key: key ?? this.key,
      );

  @override
  InlineSpan toSpan() => TextSpan(text: content);
}

class EditorSpanBold extends EditorSpanText {
  EditorSpanBold(super.content, {super.key});

  @override
  EditorNode copyWith({
    Key? key,
    String? content,
  }) =>
      EditorSpanBold(
        content ?? this.content,
        key: key ?? this.key,
      );

  @override
  InlineSpan toSpan() => TextSpan(
        text: content,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
}

class EditorParagraph extends EditorInnerNode {
  final FocusNode focusNode;

  EditorParagraph({
    required super.children,
    super.key,
    FocusNode? focusNode,
  })  : focusNode = focusNode ?? FocusNode(),
        assert(!children.any((child) => child is! EditorSpan));

  @override
  EditorParagraph copyWith({
    FocusNode? focusNode,
    IList<EditorNode>? children,
    Key? key,
  }) =>
      EditorParagraph(
        children: children ?? this.children,
        focusNode: focusNode ?? this.focusNode,
        key: key ?? this.key,
      );

  @override
  Widget build(EditorElement el) {
    //Selection selection = findParentOfType<EditorSelection>()!.selection;
    return KeyboardListener(
      focusNode: focusNode,
      child: GestureDetector(
        onTap: () => focusNode.requestFocus(),
        child: Container(
          /*color: selection.end.node == editorContext?.path
              ? MemexColor.selection
              : MemexColor.transparent,*/
          child: RichText(
            text: TextSpan(
              style: MemexTypography.body,
              children: children
                  .map((child) => (child as EditorSpan).toSpan())
                  .toList(),
            ),
          ),
        ),
      ),
      onKeyEvent: (event) {
        if (event.character != null) {
          var appendTarget = children.last;
          while (appendTarget is EditorInnerNode) {
            appendTarget = appendTarget.children.last;
          }
          assert(
            appendTarget is EditorSpan,
            "Last leaf is not an EditorSpanText but a ${appendTarget.runtimeType}",
          );
          // TODO: There is no concept of a cursor yet.
          if (event.character != null) {
            (appendTarget as EditorSpanText).append(el, event.character!);
          }
        }
      },
    );
  }
}
