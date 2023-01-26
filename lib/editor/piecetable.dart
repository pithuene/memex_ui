import 'dart:async';

import './cursor.dart';

import 'package:flutter/material.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class EditorBlock {
  EditorBlock({
    String? initialContent,
  }) {
    if (initialContent != null) {
      pieces = pieces.add(TextSpan(text: initialContent));
    }
    pieces = pieces.add(sentinelPiece);
  }

  /// An empty piece at the end of the text.
  /// The cursor is placed here to append text.
  final TextSpan sentinelPiece = const TextSpan(text: "^");

  IList<TextSpan> pieces = <TextSpan>[].lockUnsafe;

  /// Calculate the offset of the cursor in this entire editor.
  int getCursorOffset(Cursor cursor) {
    assert(cursor.block == this);
    int offset = 0;
    for (int i = 0; i < cursor.pieceIndex; i++) {
      offset += pieces[i].text!.length;
    }
    offset += cursor.offset;
    return offset;
  }
}

class ParagraphBlock extends EditorBlock {
  ParagraphBlock({String? initialContent})
      : super(initialContent: initialContent);
}

class Editor {
  late IList<EditorBlock> blocks;
  late Cursor cursor;

  Editor({
    String? initialContent,
  }) {
    blocks = [
      ParagraphBlock(initialContent: initialContent),
    ].lockUnsafe;
    cursor = Cursor(
      block: blocks[0],
      pieceIndex: 0,
      offset: 0,
    );
  }

  /// Return a new cursor one character to the right from a given one.
  Cursor moveRightOnce(Cursor cursor) {
    TextSpan currPiece = cursor.block.pieces[cursor.pieceIndex];
    if (cursor.offset < currPiece.text!.length - 1) {
      // Not at the end yet, offset can be incremented.
      return cursor.copyWith(offset: cursor.offset + 1);
    } else {
      // At the end of a piece, must jump.
      if (cursor.pieceIndex < cursor.block.pieces.length - 1) {
        // Not yet on the last piece.
        return cursor.copyWith(
          pieceIndex: cursor.pieceIndex + 1,
          offset: 0,
        );
      } else {
        return cursor;
        // TODO: This is where you should probably jump to the next block.
      }
    }
  }

  /// Move the cursor left by one character.
  Cursor moveLeftOnce(Cursor cursor) {
    TextSpan currPiece = cursor.block.pieces[cursor.pieceIndex];
    if (cursor.offset > 0) {
      // Not at the beginning yet, offset can be decremented.
      return cursor.copyWith(offset: cursor.offset - 1);
    } else {
      // At the beginning of a piece, must jump.
      if (cursor.pieceIndex > 0) {
        // Not yet on the first piece.
        return cursor.copyWith(
          pieceIndex: cursor.pieceIndex - 1,
          offset: cursor.block.pieces[cursor.pieceIndex - 1].text!.length - 1,
        );
      } else {
        return cursor;
        // TODO: This is where you should probably jump to the previous block.
      }
    }
  }

  /// Move the cursor left by a given distance.
  /// To move by one character use [moveLeftOnce].
  Cursor moveLeft(int distance, Cursor cursor) {
    Cursor curr = cursor;
    for (int i = 0; i < distance; i++) {
      curr = moveLeftOnce(cursor);
    }
    return curr;
  }

  /// Move the cursor right by a given distance.
  /// To move by one character use [moveRightOnce].
  Cursor moveRight(int distance, Cursor cursor) {
    Cursor curr = cursor;
    for (int i = 0; i < distance; i++) {
      curr = moveRightOnce(curr);
    }
    return curr;
  }

  /// Insert [newContent] before the cursor.
  void append(String newContent) {
    if (cursor.offset == 0) {
      // Cursor is at the start of the piece.
      if (cursor.pieceIndex == 0) {
        // There is no previous piece, insert one.
        TextSpan cursorPiece = cursor.block.pieces[cursor.pieceIndex];
        cursor.block.pieces = cursor.block.pieces.insert(
          0,
          TextSpan(
            text: newContent,
            style: cursorPiece.style,
          ),
        );
        // Cursor remains where it is, but the index changes because another piece was inserted in front.
        cursor = cursor.copyWith(pieceIndex: 1);
      } else {
        // Append to the previous piece.
        TextSpan previousPiece = cursor.block.pieces[cursor.pieceIndex - 1];
        cursor.block.pieces = cursor.block.pieces.replace(
          cursor.pieceIndex - 1,
          TextSpan(
            text: previousPiece.text! + newContent,
            style: previousPiece.style,
          ),
        );
      }
    } else {
      // Cursor is not at the start, piece must be split.
      // Insert first half.
      cursor.block.pieces = cursor.block.pieces.insert(
        cursor.pieceIndex,
        TextSpan(
          text: cursor.block.pieces[cursor.pieceIndex].text!
                  .substring(0, cursor.offset) +
              newContent,
          style: cursor.block.pieces[cursor.pieceIndex].style,
        ),
      );
      // Append to the second half.
      cursor.block.pieces = cursor.block.pieces.replace(
        cursor.pieceIndex + 1,
        TextSpan(
          text: cursor.block.pieces[cursor.pieceIndex + 1].text!
              .substring(cursor.offset),
          style: cursor.block.pieces[cursor.pieceIndex + 1].style,
        ),
      );
      // Cursor remains where it is, but the index changes because
      // another piece was inserted in front.
      cursor = cursor.copyWith(
        pieceIndex: cursor.pieceIndex + 1,
        offset: 0,
      );
    }
  }
}

class EditorView extends StatefulWidget {
  const EditorView({
    super.key,
    required this.editor,
  });
  final Editor editor;

  @override
  State<StatefulWidget> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (event) {
        if (event.runtimeType == KeyDownEvent ||
            event.runtimeType == KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(() {
              widget.editor.cursor =
                  widget.editor.moveRightOnce(widget.editor.cursor);
            });
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(() {
              widget.editor.cursor =
                  widget.editor.moveLeftOnce(widget.editor.cursor);
            });
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            setState(() {
              widget.editor.append("\n");
            });
            return;
          }
          if (event.character != null) {
            setState(() {
              widget.editor.append(event.character ?? "?");
            });
          }
        }
      },
      child: Column(
        children: widget.editor.blocks
            .map((block) => EditorTextView(
                  block: block,
                  cursor: widget.editor.cursor,
                ))
            .toList(),
      ),
    );
  }
}

class EditorTextView extends StatefulWidget {
  const EditorTextView({
    required this.block,
    required this.cursor,
    super.key,
  });
  final EditorBlock block;
  final Cursor cursor;

  @override
  State<EditorTextView> createState() => _EditorTextViewState();
}

class _EditorTextViewState extends State<EditorTextView> {
  final GlobalKey textKey = GlobalKey();

  Rect caretRect = Rect.zero;
  StreamController<void> caretChanged = StreamController();

  @override
  void initState() {
    super.initState();
  }

  /// To calculate where to paint the caret,
  /// the text must have already been layed out.
  /// Therefore, you need to layout a frame without the correct caret
  /// first, and then rebuild with the correct caret afterwards.
  ///
  /// This is called at every build (when the text may have changed),
  /// after the frame is draw, the caret position is recalculated
  /// and only the caret painter is rebuilt using a [StreamBuilder].
  void scheduleTextLayoutUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Rect newCaretRect = getCaretRect();
      if (newCaretRect != caretRect) {
        caretRect = newCaretRect;
        caretChanged.sink.add(null);
      }
    });
  }

  RenderParagraph? getRenderParagraph() {
    return (textKey.currentContext != null)
        ? textKey.currentContext!.findRenderObject() as RenderParagraph
        : null;
  }

  Rect getCaretRect() {
    RenderParagraph? renderParagraph = getRenderParagraph();
    if (renderParagraph == null) return Rect.zero;
    int offsetIndex = widget.block.getCursorOffset(widget.cursor);
    TextPosition position = TextPosition(
      offset: offsetIndex,
    );
    final boxes = renderParagraph.getBoxesForSelection(
      TextSelection(
        baseOffset: offsetIndex,
        extentOffset: offsetIndex + 1,
      ),
    );
    return boxes[0].toRect();
    /*Offset offset = renderParagraph.getOffsetForCaret(
      position,
      Rect.zero,
    );
    const double caretWidth = 1;
    double caretHeight = renderParagraph.getFullHeightForCaret(position) ?? 0;
    return Rect.fromLTWH(
      offset.dx - (caretWidth / 2),
      offset.dy,
      caretWidth,
      caretHeight,
    );*/
  }

  @override
  Widget build(BuildContext context) {
    scheduleTextLayoutUpdate();
    return Stack(
      children: [
        RichText(
          key: textKey,
          text: TextSpan(
            children: widget.block.pieces.unlockView,
            style: const TextStyle(color: Colors.black),
          ),
        ),
        StreamBuilder(
          stream: caretChanged.stream,
          builder: (context, snapshot) => CustomPaint(
            painter: CaretPainter(
              color: Colors.black38,
              rect: caretRect,
            ),
          ),
        ),
      ],
    );
  }
}

class CaretPainter extends CustomPainter {
  final Color color;
  final Rect rect;
  final Paint paintStyle;

  CaretPainter({
    required this.color,
    required this.rect,
  }) : paintStyle = Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    paintStyle.style = PaintingStyle.fill;
    canvas.drawRect(rect, paintStyle);
  }

  @override
  bool shouldRepaint(CaretPainter oldDelegate) {
    return true;
  }
}
