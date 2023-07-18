import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components/hover_detector.dart';
import 'package:memex_ui_examples/components/slider.dart';
import 'package:memex_ui_examples/components/state.dart';
import 'package:memex_ui_examples/components/switch.dart';
import 'package:memex_ui_examples/components/table.dart';
import 'package:memex_ui_examples/components/tree_view.dart';
import 'knobs/knob.dart';
export 'knobs/knob.dart';

List<ComponentExample> components() => [
      componentTableView(),
      componentHoverDetector(),
      componentState(),
      componentTreeView(),
      componentSwitch(),
      componentSlider(),
    ];

class ComponentExample {
  final String name;
  final List<Story> stories;

  const ComponentExample({
    required this.name,
    required this.stories,
  });
}

abstract class Story {
  final String name;
  final List<Knob> knobs;

  const Story({
    required this.name,
    this.knobs = const [],
  });

  Widget build(BuildContext context);
}
