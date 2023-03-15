import 'dart:async';
import 'dart:ui';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:memex_ui/boxed_value.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:memex_ui/editor/blocks/editor_block.dart';
import 'package:memex_ui/editor/blocks/heading_block.dart';
import 'package:memex_ui/editor/cursor.dart';
import 'package:memex_ui/editor/piece_path.dart';
import 'package:memex_ui/editor/selection.dart';
import 'package:memex_ui/memex_ui.dart';

/// Outline text boxes for debugging purposes.
const showDebugFrames = false;

class EditorTextView extends StatefulWidget {
  const EditorTextView({
    required this.block,
    required this.blockPath,
    required this.editor,
    this.style,
    super.key,
  });
  final EditorBlock block;
  final BlockPath blockPath;
  final Editor editor;
  final TextStyle? style;

  Selection get selection => editor.state.selection;
  bool get isCursorInThisBlock => selection.end.blockPath == blockPath;

  @override
  State<StatefulWidget> createState() => _EditorTextViewState();
}

class _EditorTextViewState extends State<EditorTextView> {
  Rect caretRect = Rect.zero;
  StreamController<void> caretChanged = StreamController();
  List<TextBox> selectionBoxes = [];
  final GlobalKey textKey = GlobalKey();

  StreamSubscription<void>? onCursorChangeSubscription;

  @override
  void initState() {
    super.initState();
    onCursorChangeSubscription = widget.editor.onCursorChange.stream.listen(
      (event) => updateCursorAndSelection(),
    );
  }

  @override
  void didUpdateWidget(covariant EditorTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    onCursorChangeSubscription?.cancel();
    onCursorChangeSubscription = widget.editor.onCursorChange.stream.listen(
      (event) => updateCursorAndSelection(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    onCursorChangeSubscription?.cancel();
  }

  void updateCursorAndSelection() {
    /*Rect newCaretRect = getCaretRect();
      if (newCaretRect != caretRect) {
        caretRect = newCaretRect;
        caretChanged.sink.add(null);
      }*/
    caretRect = getCaretRect();
    selectionBoxes = getSelectionBoxes();
    caretChanged.sink.add(null);
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
      updateCursorAndSelection();
    });
  }

  RenderParagraph? getRenderParagraph() {
    return (textKey.currentContext != null)
        ? textKey.currentContext!.findRenderObject() as RenderParagraph
        : null;
  }

  List<TextBox> getSelectionBoxes() {
    if (widget.selection.isEmpty) return [];
    if (!widget.selection.containsBlock(widget.blockPath)) return [];
    RenderParagraph? renderParagraph = getRenderParagraph();
    if (renderParagraph == null) return [];

    int baseOffset = (widget.selection.first.blockPath == widget.blockPath)
        ? widget.block.getCursorOffset(
            widget.selection.first,
            widget.isCursorInThisBlock,
            widget.selection.end,
          ) // Starts in this block
        : 0; // Starts before this block

    int extentOffset = (widget.selection.last.blockPath == widget.blockPath)
        ? widget.block.getCursorOffset(
            widget.selection.last,
            widget.isCursorInThisBlock,
            widget.selection.end,
          ) // Ends in this block
        : widget.block.getTotalTextLength() - 1; // Ends after this block

    final boxes = renderParagraph.getBoxesForSelection(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
      ),
    );
    return boxes;
  }

  Rect getCaretRect() {
    if (!widget.isCursorInThisBlock) return Rect.zero;
    RenderParagraph? renderParagraph = getRenderParagraph();
    if (renderParagraph == null) return Rect.zero;
    int offsetIndex = widget.block.getCursorOffset(
      widget.selection.end,
      true,
      widget.selection.end,
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

  PiecePath? findPathOfPiece(InlineSpan piece) {
    PiecePath? recursiveFindPathOfPiece(
      List<InlineSpan> pieces,
      InlineSpan target,
      PiecePath parentPath,
    ) {
      for (int i = 0; i < pieces.length; i++) {
        if (identical(pieces[i], piece)) {
          // Found piece.
          return parentPath.add(i);
        } else if (pieces[i] is TextSpan &&
            (pieces[i] as TextSpan).children != null) {
          // Is not leaf, search through children.
          PiecePath? childResult = recursiveFindPathOfPiece(
            (pieces[i] as TextSpan).children!,
            target,
            parentPath.add(i),
          );
          if (childResult != null) return childResult;
        }
      }
      return null;
    }

    RenderParagraph? renderParagraph = getRenderParagraph();
    return recursiveFindPathOfPiece(
      (renderParagraph!.text as TextSpan).children!,
      piece,
      PiecePath(<int>[].lockUnsafe),
    );
  }

  /// Find the closest cursor position for a given
  /// offset in the rendered output.
  Cursor? findCursorForOffset(Offset targetOffset) {
    RenderParagraph? renderParagraph = getRenderParagraph();
    if (renderParagraph == null) return null;

    TextPosition targetPosition =
        renderParagraph.getPositionForOffset(targetOffset);

    InlineSpan? getLeafForPositionWithOffset(
      InlineSpan parent,
      TextPosition position,
      Boxed<int> offset,
    ) {
      final Accumulator accPieceOffset = Accumulator();
      InlineSpan? result;
      parent.visitChildren((InlineSpan span) {
        result = span.getSpanForPositionVisitor(
          position,
          accPieceOffset,
        );
        return result == null;
      });
      offset.value = position.offset - accPieceOffset.value;
      return result;
    }

    Boxed<int> offset = Boxed(0);
    InlineSpan? leafSpan = getLeafForPositionWithOffset(
      renderParagraph.text,
      targetPosition,
      offset,
    );

    if (leafSpan == null) return null;

    PiecePath leafPath = findPathOfPiece(leafSpan)!;

    return Cursor(
      blockPath: widget.blockPath,
      piecePath: leafPath,
      offset: offset.value,
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
    for (int i = 0; i < widget.block.pieces.length; i++) {
      childSpans.add(
        widget.block.pieces[i].toSpan(
          widget.editor,
          widget.isCursorInThisBlock && widget.selection.end.piecePath[0] == i,
        ),
      );
    }

    return Container(
      decoration: debugBorders,
      child: Stack(
        children: [
          StreamBuilder(
            stream: caretChanged.stream,
            builder: (context, snapshot) => CustomPaint(
              painter: Textmarker(
                caretColor: Colors.black,
                caretRect: caretRect,
                selectionColor: Colors.lightBlue.withOpacity(0.5),
                selectionBoxes: selectionBoxes,
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.text,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (event) {
                Cursor? newCursor = findCursorForOffset(event.localPosition);
                if (newCursor == null) return;
                widget.editor.state = widget.editor.state.copyWith(
                  selection: Selection.collapsed(newCursor),
                );
                widget.editor.redrawCaretAndSelection();
              },
              onPanStart: (event) {
                if (event.kind != PointerDeviceKind.mouse) return;
                Cursor? newCursor = findCursorForOffset(event.localPosition);
                if (newCursor == null) return;
                widget.editor.state = widget.editor.state.copyWith(
                  selection: Selection(
                    start: newCursor,
                    end: newCursor,
                  ),
                );
                widget.editor.redrawCaretAndSelection();
              },
              onPanUpdate: (event) {
                if (widget.editor.state.selection.isEmpty) return;
                Cursor? newCursor = findCursorForOffset(event.localPosition);
                if (newCursor == null) return;
                widget.editor.state = widget.editor.state.copyWith(
                  selection:
                      widget.editor.state.selection.copyWithEnd(newCursor),
                );
                widget.editor.redrawCaretAndSelection();
              },
              child: RichText(
                key: textKey,
                text: TextSpan(
                  children: childSpans,
                  style: widget.style ?? MemexTypography.body,
                ),
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
    selectionPaintStyle.style = PaintingStyle.fill;
    selectionPaintStyle.isAntiAlias = false;
    for (TextBox selectionBox in selectionBoxes) {
      canvas.drawRect(selectionBox.toRect(), selectionPaintStyle);
    }

    caretPaintStyle.style = PaintingStyle.fill;
    caretPaintStyle.isAntiAlias = false;
    canvas.drawRect(caretRect, caretPaintStyle);
  }

  @override
  bool shouldRepaint(Textmarker oldDelegate) {
    return true;
  }
}
