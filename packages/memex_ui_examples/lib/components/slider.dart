import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components.dart';

class StorySliderDefault extends Story {
  static Prop<double> value = Prop(0.5);

  StorySliderDefault()
      : super(
          name: "Default",
          knobs: [KnobSlider("Value", value)],
        );

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Slider(value),
        ],
      );
}

ComponentExample componentSlider() => ComponentExample(
      name: "Slider",
      stories: [
        StorySliderDefault(),
      ],
    );
