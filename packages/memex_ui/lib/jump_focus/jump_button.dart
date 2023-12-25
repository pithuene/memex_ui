import 'package:memex_ui/key_label.dart';
import 'package:memex_ui/memex_ui.dart';

class Button extends ReactiveWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool usePersistentShortcut;

  const Button({
    super.key,
    this.usePersistentShortcut = false,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isJumping = JumpFocusControllerState.of(context)!.isJumping;
    final pressedKeys = JumpFocusControllerState.of(context)!.pressedKeys;

    return JumpFocusTarget(
      usePersistentShortcut: usePersistentShortcut,
      onJump: () {
        onPressed();
      },
      builder: (context, key) {
        return ReactiveBuilder(() {
          final selectable = key != null &&
              isJumping.value &&
              pressedKeys.value.length <= key.length &&
              key.sublist(0, pressedKeys.value.length) == pressedKeys.value;

          final label = KeyLabel(
            key,
            highlightCount: pressedKeys.value.length,
          );
          const duration = Duration(milliseconds: 75);
          const keyLabelWidth = 30.0;

          return AnimatedContainer(
            duration: duration,
            child: PushButton(
              controlSize: ControlSize.large,
              secondary: false,
              onPressed: onPressed,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Include a hidden key label to ensure the size doesn't change.
                  Visibility.maintain(
                    visible: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        child,
                        Container(
                          width: keyLabelWidth,
                          margin: const EdgeInsets.only(left: 5),
                          child: label,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      child,
                      AnimatedContainer(
                        duration: duration,
                        width: selectable ? keyLabelWidth : 0,
                        margin: const EdgeInsets.only(left: 5),
                        child: selectable ? label : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
