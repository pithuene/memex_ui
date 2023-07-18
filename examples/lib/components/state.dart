import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart' as mmx;
import 'package:memex_ui/state/state.dart';
import 'package:memex_ui_examples/components.dart';

class MyWidget extends ReactiveWidget {
  final Prop<int> state = Prop(0);
  MyWidget({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          state.value++;
        },
        child: Text(state.value.toString()),
      );
}

class StoryStateDefault extends Story {
  StoryStateDefault({
    super.name = "Default",
  });

  @override
  Widget build(BuildContext context) => Center(
        child: mmx.HoverDetector(
          builder: (context, hovered, _) => MyWidget(),
        ),
      );
}

class StoryStateResetOnParentRebuild extends Story {
  StoryStateResetOnParentRebuild({
    super.name = "State reset on parent rebuild",
  });

  @override
  Widget build(BuildContext context) => Center(
        child: mmx.HoverDetector(
          builder: (context, hovered, _) => Container(
            padding: const EdgeInsets.all(10),
            color: hovered ? const Color(0xFFFF0000) : const Color(0xFF0000FF),
            child: MyWidget(),
          ),
        ),
      );
}

ComponentExample componentState() => ComponentExample(
      name: "State",
      stories: [
        StoryStateDefault(),
        StoryStateResetOnParentRebuild(),
      ],
    );
