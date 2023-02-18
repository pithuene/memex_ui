import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:memex_ui/editor/piece_path.dart';

@immutable
class Piece {
  final String text;
  final bool isBold;
  final bool isItalic;
  const Piece({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
  });

  /// An empty piece which is placed at the end of every block.
  /// The cursor is placed on this to append text.
  static Piece sentinel = const Piece(text: " ");

  Piece copyWith({
    String? text,
    bool? isBold,
    bool? isItalic,
  }) {
    return Piece(
      text: text ?? this.text,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
    );
  }

  @override
  bool operator ==(Object other) => (other is Piece)
      ? (other.text == text &&
          other.isBold == isBold &&
          other.isItalic == isItalic)
      : false;

  /// The number of editable characters in the [InlineSpan]s
  /// returned by this pieces [toSpan] method.
  int getLength(bool containsCursor) => text.length;

  InlineSpan toSpan(bool containsCursor) => TextSpan(
        text: text,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
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
    IList<Piece>? children,
  }) {
    assert(text == null);
    assert(isBold == null);
    assert(isItalic == null);
    return InlineBlock(
      children: children ?? this.children,
    );
  }

  InlineBlock replaceChildren(
    IList<Piece> Function(IList<Piece>) childrenChange,
  ) =>
      copyWith(children: childrenChange(children));

  @override
  InlineSpan toSpan(bool containsCursor) {
    List<InlineSpan> childSpans = [];
    for (int i = 0; i < children.length; i++) {
      childSpans.add(children[i].toSpan(containsCursor));
    }
    return TextSpan(children: childSpans);
  }
}

/*@immutable
class LinkPiece extends Piece {
  final String target;
  const LinkPiece({
    required this.target,
    required super.text,
    required super.isBold,
    required super.isItalic,
  });
}*/
