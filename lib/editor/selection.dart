import 'package:flutter/foundation.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/cursor.dart';

@immutable
class Selection {
  final Cursor? start;
  final Cursor end;
  const Selection({
    this.start,
    required this.end,
  });

  const Selection.collapsed(this.end) : start = null;

  bool get isEmpty => start == null;

  /// Whether there is a selection which does not cross block boundaries.
  bool get isInSingleBlock => !isEmpty && start!.blockPath == end.blockPath;

  /// Either [start] or [end], whichever comes first in the document.
  Cursor get first => (end.isBefore(start!)) ? end : start!;

  /// Either [start] or [end], whichever comes later in the document.
  Cursor get last => (end.isBefore(start!)) ? start! : end;

  /// Whether the selection crosses a given [block].
  bool containsBlock(BlockPath block) {
    if (isEmpty) return false;
    if (last.blockPath.compareTo(block) >= 0 &&
        first.blockPath.compareTo(block) <= 0) {
      return true;
    } else {
      return false;
    }
  }

  /// Collapse the selection to its end.
  Selection collapse() => copyWithStart(null);

  Selection copyWithEnd(Cursor end) {
    return Selection(
      start: start,
      end: end,
    );
  }

  Selection copyWithStart(Cursor? start) {
    return Selection(
      start: start,
      end: end,
    );
  }
}
