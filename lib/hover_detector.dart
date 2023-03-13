import 'package:flutter/widgets.dart';

class HoverDetector extends StatefulWidget {
  final Widget? child;
  final Widget Function(BuildContext, bool, Widget?) builder;
  final MouseCursor? cursor;
  const HoverDetector({
    super.key,
    required this.builder,
    this.child,
    this.cursor,
  });

  @override
  State<StatefulWidget> createState() => _HoverDetectorState();
}

class _HoverDetectorState extends State<HoverDetector> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor ?? MouseCursor.defer,
      onEnter: (event) {
        if (isHovered) return;
        setState(() {
          isHovered = true;
        });
      },
      onExit: (event) {
        if (!isHovered) return;
        setState(() {
          isHovered = false;
        });
      },
      child: widget.builder(context, isHovered, widget.child),
    );
  }
}
