import 'package:memex_ui/key_label.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/overlay.dart';
import 'package:memex_ui_examples/components.dart';

class StoryJumpFocusDefault extends Story {
  static Prop<double> value = Prop(0.5);

  StoryJumpFocusDefault()
      : super(
          name: "Default",
          knobs: [KnobSlider("Value", value)],
        );

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ReactiveBuilder(() =>
              JumpFocusControllerState.of(context)!.isJumping.value
                  ? Text("Jumping focus")
                  : Text("Not jumping focus")),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Button(
                  child: Text("Jump 1"),
                  usePersistentShortcut: true,
                  onPressed: () {
                    print("Jump button 1 pressed");
                  },
                ),
                Text("Hello World"),
                Button(
                  usePersistentShortcut: true,
                  child: const Row(children: [
                    Icon(
                      CupertinoIcons.profile_circled,
                      color: MemexColor.white,
                      size: 18,
                    ),
                    SizedBox(width: 5),
                    Text("Jump 1"),
                  ]),
                  onPressed: () {
                    print("Jump button 2 pressed");
                    openOverlay(
                      context,
                      (context, entry) => Container(
                        padding: const EdgeInsets.all(20),
                        width: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: MemexColor.grid),
                          color: MemexColor.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Welcome to this overlay."),
                            const SizedBox(height: 20),
                            Button(
                              onPressed: () {
                                entry.remove();
                              },
                              child: const Text("Close"),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
}

ComponentExample componentJumpFocus() => ComponentExample(
      name: "Jump Focus",
      stories: [
        StoryJumpFocusDefault(),
      ],
    );
