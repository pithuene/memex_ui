import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

class _MemexUIExamplesAppState extends State<MemexUIExamplesApp> {
  ComponentExample? currentComponent;
  Story? currentStory;

  @override
  Widget build(BuildContext context) {
    return mmx.App(
      appName: "MemexUI Examples",
      builder: (context, scrollController) =>
          currentStory == null ? Container() : currentStory!.build(context),
      toolBar: mmx.ToolBar(
        title: Row(children: [
          Text(currentComponent?.name ?? "MemexUI Examples"),
          ...currentStory == null
              ? []
              : [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: mmx.MacosIcon(
                      CupertinoIcons.chevron_right,
                      color: MemexTypography.textColor,
                      size: 16,
                    ),
                  ),
                ],
          Text(currentStory?.name ?? ""),
        ]),
        titleWidth: 300,
      ),
      sidebar: mmx.Sidebar(
        topOffset: 0,
        minWidth: 250,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          children: components()
              .map(
                (component) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(component.name),
                      ...component.stories.map((story) {
                        if (component.name == currentComponent?.name &&
                            story.name == currentStory?.name) {
                          currentStory = story;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                currentStory = story;
                                currentComponent = component;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(story.name),
                            ),
                          ),
                        );
                      }).toList(),
                    ]),
              )
              .toList(),
        ),
      ),
      endSidebar: mmx.Sidebar(
        minWidth: 250,
        topOffset: 0,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          children: [
            Text("Knobs"),
          ],
        ),
      ),
    );
  }
}
