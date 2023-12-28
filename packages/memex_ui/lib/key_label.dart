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

  TextSpan _buildTextSpan() {
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

  /// Calculate the size of the widget without building it.
  Size calculateSize() {
    final textPainter = TextPainter(
      text: _buildTextSpan(),
      textWidthBasis: TextWidthBasis.longestLine,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout();
    return Size(
      textPainter.width + padding.width * 2 + borderWidth * 2,
      textPainter.height + padding.height * 2 + borderWidth * 2,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
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
        child: Text.rich(
          _buildTextSpan(),
          maxLines: 1,
        ),
      );
}
