import 'package:flutter/widgets.dart';
import 'package:memex_ui_examples/components/table.dart';

final List<ComponentExample> components = [
  componentTableView,
];

class ComponentExample {
  final String name;
  final List<Story> stories;

  ComponentExample({
    required this.name,
    required this.stories,
  });
}

class Story {
  Widget Function(BuildContext) build;
  String name;
  Story(this.name, this.build);
}
