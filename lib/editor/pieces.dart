import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

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

  InlineSpan toSpan() => TextSpan(
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
class LinkPiece extends Piece {
  final String target;
  const LinkPiece({
    required this.target,
    required super.text,
    required super.isBold,
    required super.isItalic,
  });
}
