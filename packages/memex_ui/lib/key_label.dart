import 'package:flutter/services.dart';
import 'package:memex_ui/memex_ui.dart';

/// A widget that displays a shortcut key combination.
class KeyLabel extends StatelessWidget {
  final Shortcut? shortcut;

  /// The first n keys are highlighted.
  final int highlightCount;

  const KeyLabel(
    this.shortcut, {
    super.key,
    this.highlightCount = 0,
  });

  static const Size padding = Size(2, 1);
  static const double borderWidth = 1.0;

  static final textStyle = MemexTypography.body.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  static TextSpan _buildTextSpan(Shortcut? shortcut, int highlightCount) {
    final textSpans = shortcut?.mapIndexedAndLast(
      (index, item, isLast) => TextSpan(
        text: item.keyLabel,
        style: textStyle.copyWith(
          inherit: false,
          color: index < highlightCount
              ? MemexColor.text
              : MemexColor.text.withOpacity(0.5),
          overflow: TextOverflow.visible,
        ),
      ),
    );
    return TextSpan(children: textSpans?.toList() ?? <InlineSpan>[]);
  }

  Size _calculateTextContentSize() {
    final textPainter = TextPainter(
      text: _buildTextSpan(
        // The key label size is independent on the content, a placeholder is fine.
        // Otherwise, it wouldn't be possible to calculate the required
        // space for a key label before allocating a shortcut for it.
        Shortcut(const [LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyW]),
        0,
      ),
      textWidthBasis: TextWidthBasis.longestLine,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout();
    return Size(textPainter.width, textPainter.height);
  }

  /// Calculate the size of the widget without building it.
  Size calculateSize() {
    final textContentSize = _calculateTextContentSize();
    return Size(
      textContentSize.width + padding.width * 2 + borderWidth * 2,
      textContentSize.height + padding.height * 2 + borderWidth * 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    Size textContentSize = _calculateTextContentSize();
    return Container(
      decoration: BoxDecoration(
        color: MemexColor.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: MemexColor.grid,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: MemexColor.black.withOpacity(0.1),
            blurRadius: 2,
            blurStyle: BlurStyle.normal,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: padding.width,
        vertical: padding.height,
      ),
      child: SizedBox(
        width: textContentSize.width,
        height: textContentSize.height,
        child: Text.rich(
          _buildTextSpan(shortcut, highlightCount),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}
