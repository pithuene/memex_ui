import 'package:memex_ui/memex_ui.dart';

class TreeViewNode {
  /// Use a Container() to leave the icon space empty.
  /// Use null if none of the entries have icons.
  final Widget? icon;

  final InlineSpan label;

  final void Function(TreeViewNode)? onTap;

  /// null means this is an inner node.
  final Iterable<TreeViewNode>? children;

  const TreeViewNode({
    this.icon,
    required this.label,
    this.onTap,
    this.children,
  });

  Widget build(BuildContext context) => HoverDetector(
        cursor: SystemMouseCursors.click,
        builder: (context, isHovered, child) => Container(
          decoration: BoxDecoration(
            color: isHovered && onTap != null
                ? MemexColor.shade
                : MemexColor.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          ),
          child: child,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (onTap != null) onTap!(this);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  ...icon == null
                      ? []
                      : [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: SizedBox.square(
                              dimension: MemexTypography.baseFontSize,
                              child: icon!,
                            ),
                          ),
                          const TextSpan(text: " "),
                        ],
                  label,
                ],
              ),
              style: MemexTypography.body.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
}

class TreeView extends StatelessWidget {
  final Iterable<TreeViewNode> items;
  const TreeView({
    super.key,
    required this.items,
  });

  List<Widget> _recursiveBuild(
    BuildContext context,
    int depth,
    Iterable<TreeViewNode> nodes,
  ) {
    const double nestingOffset = MemexTypography.baseFontSize;

    List<Widget> result = [];
    for (TreeViewNode node in nodes) {
      result.add(Padding(
        padding: EdgeInsets.only(left: depth * nestingOffset),
        child: node.build(context),
      ));
      if (node.children != null) {
        result.addAll(_recursiveBuild(context, depth + 1, node.children!));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(10),
        children: _recursiveBuild(context, 0, items),
      );
}
