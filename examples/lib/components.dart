import 'package:flutter/widgets.dart';
import 'package:memex_ui_examples/components/hover_detector.dart';
import 'package:memex_ui_examples/components/state.dart';
import 'package:memex_ui_examples/components/table.dart';
import 'package:memex_ui_examples/components/tree_view.dart';

List<ComponentExample> components() => [
      componentTableView(),
      componentHoverDetector(),
      componentState(),
      componentTreeView(),
    ];

class ComponentExample {
  final String name;
  final List<Story> stories;

  const ComponentExample({
    required this.name,
    required this.stories,
  });
}

class Story {
  final Widget Function(BuildContext) build;
  final String name;
  const Story(this.name, this.build);
}
