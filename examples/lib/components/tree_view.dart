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
          children: [
            TreeViewNode(
              label: const TextSpan(text: "One"),
              icon: const MemexIcon(CupertinoIcons.add),
              onTap: (_) {},
            ),
            TreeViewNode(
              label: const TextSpan(text: "Two"),
              icon: const SizedBox.shrink(),
              onTap: (_) {},
            ),
            TreeViewNode(
              label: const TextSpan(text: "Three"),
              icon: const SizedBox.shrink(),
              onTap: (_) {},
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
