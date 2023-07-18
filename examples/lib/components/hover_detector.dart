import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components.dart';

class StoryHoverDetectorDefault extends Story {
  StoryHoverDetectorDefault({
    super.name = "Default",
  });

  @override
  Widget build(BuildContext context) => Center(
        child: HoverDetector(
          builder: (context, hovered, child) => Container(
            color: hovered ? const Color(0xFFFF0000) : const Color(0xFF0000FF),
            child: child,
          ),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Text("Content"),
          ),
        ),
      );
}

ComponentExample componentHoverDetector() => ComponentExample(
      name: "HoverDetector",
      stories: [
        StoryHoverDetectorDefault(),
      ],
    );
