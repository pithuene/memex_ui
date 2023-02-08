import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:memex_ui/editor/block_path.dart';

import './cursor.dart';
import './block.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Outline text boxes for debugging purposes.
const showDebugFrames = true;

class EditorTextView extends StatelessWidget {
  EditorTextView({
    required this.block,
    required this.blockPath,
    this.cursor,
    this.style = const TextStyle(
      color: Colors.black,
      fontFamily: "Inter",
    ),
    super.key,
  });
  final EditorBlock block;
  final BlockPath blockPath;
  final Cursor? cursor;
  final TextStyle style;

  final GlobalKey textKey = GlobalKey();

  Rect caretRect = Rect.zero;
  StreamController<void> caretChanged = StreamController();

  bool get isCursorInThisBlock => cursor?.blockPath == blockPath;

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
    if (cursor == null || !isCursorInThisBlock) return Rect.zero;
    RenderParagraph? renderParagraph = getRenderParagraph();
    if (renderParagraph == null) return Rect.zero;
    int offsetIndex = block.getCursorOffset(cursor!);
    TextPosition position = TextPosition(offset: offsetIndex);
    /*final boxes = renderParagraph.getBoxesForSelection(
      TextSelection(
        baseOffset: offsetIndex,
        extentOffset: offsetIndex + 1,
      ),
    );
    return boxes[0].toRect();*/
    Offset offset = renderParagraph.getOffsetForCaret(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    scheduleTextLayoutUpdate();

    BoxDecoration? debugBorders;
    if (showDebugFrames && kDebugMode) {
      debugBorders = BoxDecoration(border: Border.all());
    }

    return Container(
      decoration: debugBorders,
      child: Stack(
        children: [
          RichText(
            key: textKey,
            text: TextSpan(
              children: block.pieces.unlockView,
              style: style,
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
      ),
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
