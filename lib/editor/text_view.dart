import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/memex_ui.dart';

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
    required this.selection,
    this.style = const TextStyle(
      color: Colors.black,
      fontFamily: "Inter",
    ),
    super.key,
  });
  final EditorBlock block;
  final BlockPath blockPath;
  final Selection selection;
  final TextStyle style;

  final GlobalKey textKey = GlobalKey();

  Rect caretRect = Rect.zero;
  StreamController<void> caretChanged = StreamController();
  List<TextBox> selectionBoxes = [];

  bool get isCursorInThisBlock => selection.end.blockPath == blockPath;

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
      /*Rect newCaretRect = getCaretRect();
      if (newCaretRect != caretRect) {
        caretRect = newCaretRect;
        caretChanged.sink.add(null);
      }*/
      caretRect = getCaretRect();
      selectionBoxes = getSelectionBoxes();
      caretChanged.sink.add(null);
    });
  }

  RenderParagraph? getRenderParagraph() {
    return (textKey.currentContext != null)
        ? textKey.currentContext!.findRenderObject() as RenderParagraph
        : null;
  }

  List<TextBox> getSelectionBoxes() {
    bool isPartOfSelection = selection.containsBlock(blockPath);
    RenderParagraph? renderParagraph = getRenderParagraph();
    if (renderParagraph == null) return [];
    final boxes = renderParagraph.getBoxesForSelection(
      TextSelection(
        baseOffset: 0,
        extentOffset: 1,
      ),
    );
    return boxes;
  }

  Rect getCaretRect() {
    if (!isCursorInThisBlock) return Rect.zero;
    RenderParagraph? renderParagraph = getRenderParagraph();
    if (renderParagraph == null) return Rect.zero;
    int offsetIndex = block.getCursorOffset(selection.end);
    TextPosition position = TextPosition(offset: offsetIndex);
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
                caretColor: Colors.black38,
                caretRect: caretRect,
                selectionColor: Colors.lightBlue.withOpacity(0.5),
                selectionBoxes: selectionBoxes,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CaretPainter extends CustomPainter {
  final Color caretColor;
  final Rect caretRect;

  final Color selectionColor;
  final List<TextBox> selectionBoxes;

  final Paint caretPaintStyle;
  final Paint selectionPaintStyle;

  CaretPainter({
    required this.caretColor,
    required this.caretRect,
    required this.selectionColor,
    required this.selectionBoxes,
  })  : caretPaintStyle = Paint()..color = caretColor,
        selectionPaintStyle = Paint()..color = selectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    caretPaintStyle.style = PaintingStyle.fill;
    canvas.drawRect(caretRect, caretPaintStyle);

    selectionPaintStyle.style = PaintingStyle.fill;
    for (TextBox selectionBox in selectionBoxes) {
      canvas.drawRect(selectionBox.toRect(), selectionPaintStyle);
    }
  }

  @override
  bool shouldRepaint(CaretPainter oldDelegate) {
    return true;
  }
}
