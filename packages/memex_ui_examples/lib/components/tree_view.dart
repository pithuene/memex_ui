import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components.dart';

class StoryTreeViewDefault extends Story {
  StoryTreeViewDefault({
    super.name = "Default",
  });

  @override
  Widget build(BuildContext context) => TreeView(items: [
        TreeViewNode(
          label: const TextSpan(text: "One"),
          icon: const SizedBox.shrink(),
          onTap: (_) {},
        ),
        TreeViewNode(
          label: const TextSpan(text: "Two"),
          icon: const MemexIcon(CupertinoIcons.pen),
          onTap: (_) {},
          children: const [
            TreeViewNode(
              label: TextSpan(text: "One"),
              icon: MemexIcon(CupertinoIcons.add),
            ),
            TreeViewNode(
              label: TextSpan(text: "Two"),
              icon: SizedBox.shrink(),
            ),
            TreeViewNode(
              label: TextSpan(text: "Three"),
              icon: SizedBox.shrink(),
            ),
          ],
        ),
        TreeViewNode(
          label: const TextSpan(text: "Three"),
          icon: const MemexIcon(CupertinoIcons.book),
          onTap: (_) {},
        ),
      ]);
}

ComponentExample componentTreeView() => ComponentExample(
      name: "TreeView",
      stories: [
        StoryTreeViewDefault(),
      ],
    );
