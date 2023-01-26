import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart';

import './block.dart';

@immutable
class Cursor {
  const Cursor({
    required this.block,
    required this.pieceIndex,
    required this.offset,
  });

  final EditorBlock block;
  final int pieceIndex;
  final int offset;

  Cursor copyWith({
    EditorBlock? block,
    int? pieceIndex,
    int? offset,
  }) {
    return Cursor(
      block: block ?? this.block,
      pieceIndex: pieceIndex ?? this.pieceIndex,
      offset: offset ?? this.offset,
    );
  }
}
