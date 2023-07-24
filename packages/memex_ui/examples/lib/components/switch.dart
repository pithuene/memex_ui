import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components.dart';

class StorySwitchDefault extends Story {
  StorySwitchDefault({
    super.name = "Default",
  });

  @override
  Widget build(BuildContext context) => Switch(Prop(false));
}

class StorySwitchWithKnob extends Story {
  static Prop<bool> switchKnob = Prop(false);

  StorySwitchWithKnob()
      : super(name: "With Knob", knobs: [
          KnobSwitch("State", switchKnob),
        ]);

  @override
  Widget build(BuildContext context) =>
      Text(switchKnob.value ? "true" : "false");
}

ComponentExample componentSwitch() => ComponentExample(
      name: "Switch",
      stories: [
        StorySwitchDefault(),
        StorySwitchWithKnob(),
      ],
    );
