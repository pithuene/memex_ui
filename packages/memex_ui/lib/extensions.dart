import 'package:flutter/cupertino.dart';
import 'package:memex_ui/memex_ui.dart';

extension StringToText on String {
  Text toText() => Text(this);
  Text toExtraLargeTitle() =>
      Text(this, style: MemexTypography.extraLargeTitle);
  Text toLargeTitle() => Text(this, style: MemexTypography.largeTitle);
  Text toTitle() => Text(this, style: MemexTypography.title);
  Text toSubtitle() => Text(this, style: MemexTypography.subtitle);
}

/// A rounded highlight box around a widget.
extension Highlight on Widget {
  Widget highlight({
    /// An active highlight is blue, an inactive highlight is grey.
    bool active = false,

    /// Control whether there is a highlight at all.
    /// Useful for when you want to highlight something on hover.
    bool visible = true,
  }) =>
      Builder(
        builder: (context) => DecoratedBox(
          decoration: BoxDecoration(
            color: !visible
                ? const Color(0x00000000)
                : (active ? CupertinoColors.activeBlue : MemexColor.shade),
            borderRadius: MemexBorder.radius,
          ),
          child: DefaultTextStyle(
            style: active
                ? DefaultTextStyle.of(context)
                    .style
                    .copyWith(color: MemexColor.white)
                : DefaultTextStyle.of(context).style,
            child: this,
          ),
        ),
      );
}

extension Card on Widget {
  Widget outlined() => Container(
        decoration: BoxDecoration(
          color: MemexColor.white,
          border: MemexBorder.all,
          borderRadius: BorderRadius.circular(8),
        ),
        child: this,
      );
}

extension StyledIterable<E> on Iterable<Widget> {
  Widget toColumn({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    Widget? separator,
  }) =>
      toList().toColumn(
        key: key,
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        separator: separator,
      );

  Widget toRow({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    Widget? separator,
  }) =>
      toList().toRow(
        key: key,
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        separator: separator,
      );

  Widget toStack({
    Key? key,
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    TextDirection? textDirection,
    StackFit fit = StackFit.loose,
    Clip clipBehavior = Clip.hardEdge,
    List<Widget> children = const <Widget>[],
  }) =>
      toList().toStack(
        key: key,
        alignment: alignment,
        textDirection: textDirection,
        fit: fit,
        clipBehavior: clipBehavior,
        children: children,
      );
}
