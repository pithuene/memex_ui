import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components.dart';

Prop<bool> switchState = Prop(false);

ComponentExample componentSwitch() => ComponentExample(
      name: "Switch",
      stories: [
        Story("Default", (context) => Switch(switchState)),
        Story(
          "Shared State",
          (context) => Column(children: [
            Switch(switchState),
            Switch(switchState),
          ]),
        ),
      ],
    );
