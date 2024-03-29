import 'package:flutter/cupertino.dart';
import 'package:memex_ui/color.dart';
import 'package:memex_ui/memex_ui.dart' as mmx;
import 'package:memex_ui/typography.dart';
import 'package:memex_ui_examples/components.dart';

void main() {
  runApp(const MemexUIExamplesApp());
}

class MemexUIExamplesApp extends StatefulWidget {
  const MemexUIExamplesApp({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _MemexUIExamplesAppState();
}

class ComponentTreeViewNode extends mmx.TreeViewNode {
  const ComponentTreeViewNode({
    required super.label,
    super.children,
  });

  @override
  Widget build(BuildContext context) => Text.rich(
        label,
        style: MemexTypography.body.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: MemexTypography.baseFontSize * 0.9,
          color: MemexColor.text.withAlpha(64),
        ),
      ).padding(
        bottom: 3,
        top: 15,
        left: 5,
      );
}

class _MemexUIExamplesAppState extends State<MemexUIExamplesApp> {
  ComponentExample? currentComponent;
  Story? currentStory;

  @override
  Widget build(BuildContext context) {
    return mmx.App(
      appName: "MemexUI Examples",
      builder: (context, scrollController) => currentStory == null
          ? Container()
          : mmx.ReactiveBuilder(() => currentStory!.build(context)),
      toolBar: mmx.ToolBar(
        title: [
          Text(currentComponent?.name ?? "MemexUI Examples"),
          if (currentStory != null)
            const mmx.MemexIcon(CupertinoIcons.chevron_right)
                .padding(horizontal: 5),
          Text(currentStory?.name ?? ""),
        ].toRow(),
        titleWidth: 300,
      ),
      sidebar: mmx.Sidebar(
        topOffset: 0,
        minWidth: 250,
        builder: (context, scrollController) => mmx.TreeView(
          items: components().map((component) => ComponentTreeViewNode(
                label: TextSpan(text: component.name),
                children: component.stories.map((story) {
                  final bool isCurrentStory =
                      component.name == currentComponent?.name &&
                          story.name == currentStory?.name;
                  if (isCurrentStory) {
                    currentStory = story;
                  }
                  return mmx.TreeViewNode(
                    label: TextSpan(text: story.name),
                    usePersistentShortcuts: true,
                    isSelected: isCurrentStory,
                    onTap: (_) {
                      setState(() {
                        currentStory = story;
                        currentComponent = component;
                      });
                    },
                  );
                }),
              )),
        ),
      ),
      endSidebar: mmx.Sidebar(
        minWidth: 250,
        topOffset: 0,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(10),
          children: currentStory?.knobs
                  .map(
                    (knob) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          knob.label,
                          style: MemexTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: MemexTypography.baseFontSize * 0.9,
                            color: MemexColor.text.withAlpha(64),
                          ),
                        ),
                        knob.build(context),
                        const SizedBox(height: 12),
                      ],
                    ),
                  )
                  .toList() ??
              [],
        ),
      ),
    );
  }
}
