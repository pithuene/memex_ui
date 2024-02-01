import 'package:memex_ui/jump_focus/jump_target_row.dart';
import 'package:memex_ui/memex_ui.dart';

class TreeViewNode {
  /// Use a Container() to leave the icon space empty.
  /// Use null if none of the entries have icons.
  final Widget? icon;

  final InlineSpan label;

  final void Function(TreeViewNode)? onTap;

  /// null means this is an inner node.
  final Iterable<TreeViewNode>? children;

  /// Whether to use persistent shortcuts for the jump targets.
  /// This is useful when the tree is rather small and static.
  final bool usePersistentShortcuts;

  final bool isSelected;

  const TreeViewNode({
    this.icon,
    required this.label,
    this.usePersistentShortcuts = false,
    this.onTap,
    this.children,
    this.isSelected = false,
  });

  Widget build(BuildContext context) => DefaultTextStyle(
        style: MemexTypography.body,
        child: HoverDetector(
          cursor: SystemMouseCursors.click,
          builder: (context, isHovered, child) => child!.highlight(
            visible: isHovered || isSelected,
            active: isSelected,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (onTap != null) onTap!(this);
            },
            child: JumpFocusTarget(
              disabled: onTap == null,
              usePersistentShortcut: usePersistentShortcuts,
              onJump: () {
                if (onTap != null) onTap!(this);
              },
              builder: (context, key, isSelectable) => JumpTargetRow(
                shortcut: key,
                showTarget: isSelectable,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                targetMargin: const (5, 0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (icon != null)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: SizedBox.square(
                            dimension: MemexTypography.baseFontSize,
                            child: icon!,
                          ),
                        ),
                      if (icon != null) const TextSpan(text: " "),
                      label,
                    ],
                  ).fontWeight(FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ).expanded(),
              ),
            ).padding(horizontal: 10, vertical: 6),
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
      result.add(
        node.build(context).padding(left: depth * nestingOffset),
      );
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
