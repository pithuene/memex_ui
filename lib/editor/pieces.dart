import 'package:flutter_math_fork/flutter_math.dart';
import 'package:memex_ui/memex_ui.dart';

@immutable
class Piece {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isMonospace;
  const Piece({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isMonospace = false,
  });

  /// An empty piece which is placed at the end of every block.
  /// The cursor is placed on this to append text.
  static Piece sentinel = const Piece(text: " ");

  Piece copyWith({
    String? text,
    bool? isBold,
    bool? isItalic,
    bool? isMonospace,
  }) {
    return Piece(
      text: text ?? this.text,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isMonospace: isMonospace ?? this.isMonospace,
    );
  }

  @override
  bool operator ==(Object other) => (other is Piece)
      ? (other.text == text &&
          other.isBold == isBold &&
          other.isItalic == isItalic &&
          other.isMonospace == isMonospace)
      : false;

  /// The number of editable characters in the [InlineSpan]s
  /// returned by this pieces [toSpan] method.
  int getLength(bool containsCursor) => text.length;

  InlineSpan toSpan(Editor editor, bool containsCursor) => TextSpan(
        text: text,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : null,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          fontFamily: isMonospace ? MemexTypography.fontFamilyMonospace : null,
          backgroundColor: isMonospace ? MemexColor.shade : null,
        ),
      );

  Piece substring(int start, [int? end]) {
    if (end != null && end < 0) {
      return copyWith(text: text.substring(start, text.length + end));
    }
    return copyWith(text: text.substring(start, end));
  }

  Piece replaceRange(int start, int? end, String replacement) =>
      copyWith(text: text.replaceRange(start, end, replacement));

  Piece append(String newContent) => copyWith(text: text + newContent);
}

@immutable
class InlineBlock extends Piece {
  final IList<Piece> children;
  const InlineBlock({
    required this.children,
  }) : super(
          text: "",
          isBold: false,
          isItalic: false,
        );

  @override
  int getLength(bool containsCursor) {
    return children.sumBy((child) => child.getLength(containsCursor));
  }

  bool get hasChildren => children.isNotEmpty;

  @override
  InlineBlock copyWith({
    String? text,
    bool? isBold,
    bool? isItalic,
    bool? isMonospace,
    IList<Piece>? children,
  }) {
    assert(text == null);
    assert(isBold == null);
    assert(isItalic == null);
    assert(isMonospace == null);
    return InlineBlock(
      children: children ?? this.children,
    );
  }

  InlineBlock replaceChildren(
    IList<Piece> Function(IList<Piece>) childrenChange,
  ) =>
      copyWith(children: childrenChange(children));

  @override
  InlineSpan toSpan(Editor editor, bool containsCursor) => TextSpan(
        children: children
            .map((piece) => piece.toSpan(editor, containsCursor))
            .toList(),
      );
}

@immutable
class LinkPiece extends InlineBlock {
  final String target;
  const LinkPiece({
    required super.children,
    required this.target,
  });

  @override
  int getLength(bool containsCursor) {
    if (containsCursor) {
      return super.getLength(containsCursor);
    } else {
      return super.getLength(containsCursor) + 1;
    }
  }

  @override
  InlineSpan toSpan(Editor editor, bool containsCursor) {
    if (containsCursor) {
      return TextSpan(
        children: children.map((piece) => piece.toSpan(editor, true)).toList(),
        style: const TextStyle(
          decoration: TextDecoration.underline,
        ),
      );
    } else {
      var res = TextSpan(
        children: [
          WidgetSpan(
            baseline: TextBaseline.alphabetic,
            alignment: PlaceholderAlignment.baseline,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => editor.openLink(target),
                child: const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: MemexIcon(CupertinoIcons.doc),
                ),
              ),
            ),
          ),
          ...children.map((piece) => piece.toSpan(editor, false))
        ],
        style: MemexTypography.body.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: MemexColor.grid,
        ),
      );
      return res;
    }
  }

  @override
  InlineBlock copyWith({
    String? target,
    String? text,
    bool? isBold,
    bool? isItalic,
    bool? isMonospace,
    IList<Piece>? children,
  }) {
    return LinkPiece(
      children: children ?? this.children,
      target: target ?? this.target,
    );
  }
}

@immutable
class FootnotePiece extends InlineBlock {
  const FootnotePiece({
    required super.children,
  });

  @override
  int getLength(bool containsCursor) {
    if (containsCursor) {
      return super.getLength(containsCursor);
    } else {
      return 1;
    }
  }

  @override
  InlineSpan toSpan(Editor editor, bool containsCursor) {
    if (containsCursor) {
      return TextSpan(
        children: [super.toSpan(editor, containsCursor)],
        style: const TextStyle(
          backgroundColor: Color(0x20000000),
        ),
      );
    } else {
      return const TextSpan(text: "¹");
    }
  }

  @override
  InlineBlock copyWith({
    String? text,
    bool? isBold,
    bool? isItalic,
    bool? isMonospace,
    IList<Piece>? children,
  }) {
    return FootnotePiece(
      children: children ?? this.children,
    );
  }
}

@immutable
class InlineMathPiece extends InlineBlock {
  const InlineMathPiece({
    required super.children,
  });

  @override
  int getLength(bool containsCursor) {
    if (containsCursor) {
      return children.sumBy((child) => child.getLength(containsCursor));
    } else {
      return 1;
    }
  }

  @override
  InlineSpan toSpan(Editor editor, bool containsCursor) {
    if (containsCursor) {
      return TextSpan(
        children: [super.toSpan(editor, containsCursor)],
        style: const TextStyle(
          fontFamily: MemexTypography.fontFamilyMonospace,
          backgroundColor: MemexColor.shade,
        ),
      );
    } else {
      String tex = TextSpan(
        children: children
            .map(
              (child) => child.toSpan(editor, containsCursor),
            )
            .toList(),
      ).toPlainText();
      return WidgetSpan(
        baseline: TextBaseline.alphabetic,
        alignment: PlaceholderAlignment.baseline,
        child: Math.tex(
          tex,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
          mathStyle: MathStyle.text,
        ),
      );
    }
  }

  @override
  InlineBlock copyWith({
    String? text,
    bool? isBold,
    bool? isItalic,
    bool? isMonospace,
    IList<Piece>? children,
  }) {
    return InlineMathPiece(
      children: children ?? this.children,
    );
  }
}
