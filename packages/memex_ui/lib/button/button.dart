import 'package:memex_ui/jump_focus/jump_target_row.dart';
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
    return JumpFocusTarget(
      usePersistentShortcut: usePersistentShortcut,
      onJump: () {
        onPressed();
      },
      builder: (context, key, isSelectable) {
        return PushButton(
          controlSize: ControlSize.large,
          secondary: false,
          onPressed: onPressed,
          child: JumpTargetRow(
            targetMargin: const (5, 0),
            showTarget: isSelectable,
            shortcut: key,
            child: child,
          ),
        );
      },
    );
  }
}
