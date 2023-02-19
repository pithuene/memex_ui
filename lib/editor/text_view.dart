import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:memex_ui/editor/blocks/editor_block.dart';
import 'package:memex_ui/editor/selection.dart';

/// Outline text boxes for debugging purposes.
const showDebugFrames = false;

class EditorTextView extends StatelessWidget {
  EditorTextView({
    required this.block,
    required this.blockPath,
    required this.selection,
    this.style = const TextStyle(
      color: Colors.black,
      fontFamily: "Inter",
      fontSize: 16,
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
    if (selection.isEmpty) return [];
    if (!selection.containsBlock(blockPath)) return [];
    RenderParagraph? renderParagraph = getRenderParagraph();
    if (renderParagraph == null) return [];

    int baseOffset = (selection.first.blockPath == blockPath)
        ? block.getCursorOffset(
            selection.first,
            isCursorInThisBlock,
            selection.end,
          ) // Starts in this block
        : 0; // Starts before this block

    int extentOffset = (selection.last.blockPath == blockPath)
        ? block.getCursorOffset(
            selection.last,
            isCursorInThisBlock,
            selection.end,
          ) // Ends in this block
        : block.getTotalTextLength() - 1; // Ends after this block

    final boxes = renderParagraph.getBoxesForSelection(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
      ),
    );
    return boxes;
  }

  Rect getCaretRect() {
    if (!isCursorInThisBlock) return Rect.zero;
    RenderParagraph? renderParagraph = getRenderParagraph();
    if (renderParagraph == null) return Rect.zero;
    int offsetIndex = block.getCursorOffset(
      selection.end,
      true,
      selection.end,
    );
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

    List<InlineSpan> childSpans = [];
    for (int i = 0; i < block.pieces.length; i++) {
      childSpans.add(
        block.pieces[i].toSpan(
          isCursorInThisBlock && selection.end.piecePath[0] == i,
        ),
      );
    }

    return Container(
      decoration: debugBorders,
      child: Stack(
        children: [
          RichText(
            key: textKey,
            text: TextSpan(
              children: childSpans,
              style: style,
            ),
          ),
          StreamBuilder(
            stream: caretChanged.stream,
            builder: (context, snapshot) => CustomPaint(
              painter: Textmarker(
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

class Textmarker extends CustomPainter {
  final Color caretColor;
  final Rect caretRect;

  final Color selectionColor;
  final List<TextBox> selectionBoxes;

  final Paint caretPaintStyle;
  final Paint selectionPaintStyle;

  Textmarker({
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
  bool shouldRepaint(Textmarker oldDelegate) {
    return true;
  }
}
