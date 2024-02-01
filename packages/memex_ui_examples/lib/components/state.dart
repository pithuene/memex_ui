import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart';
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
  Widget build(BuildContext context) =>
      HoverDetector(builder: (context, hovered, _) => MyWidget()).center();
}

class StoryStateResetOnParentRebuild extends Story {
  StoryStateResetOnParentRebuild({
    super.name = "State reset on parent rebuild",
  });

  @override
  Widget build(BuildContext context) => HoverDetector(
        builder: (context, hovered, _) => MyWidget()
            .padding(all: 20)
            .backgroundColor(MemexColor.white)
            .elevation(hovered ? 10 : 0)
            .animate(const Duration(milliseconds: 100), Curves.easeOutCubic),
      ).center();
}

ComponentExample componentState() => ComponentExample(
      name: "State",
      stories: [
        StoryStateDefault(),
        StoryStateResetOnParentRebuild(),
      ],
    );
