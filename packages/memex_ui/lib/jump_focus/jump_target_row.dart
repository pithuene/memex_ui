import 'package:memex_ui/key_label.dart';
import 'package:memex_ui/memex_ui.dart';

class JumpTargetRow extends StatelessWidget {
  final Widget child;
  final Shortcut? shortcut;
  final MainAxisAlignment mainAxisAlignment;
  final bool showTarget;

  /// The horizontal margin around the jump target.
  final (double, double) targetMargin;

  static const Duration animationDuration = Duration(milliseconds: 75);

  /// A row that includes a jump target.
  /// The size doesn't change when the jump target becomes visible.
  const JumpTargetRow({
    super.key,
    this.targetMargin = const (0, 0),
    this.mainAxisAlignment = MainAxisAlignment.center,
    required this.shortcut,
    required this.showTarget,
    required this.child,
  }) : assert(mainAxisAlignment == MainAxisAlignment.center ||
            mainAxisAlignment == MainAxisAlignment.spaceBetween);

  @override
  Widget build(BuildContext context) {
    final pressedKeys = JumpFocusControllerState.of(context)!.pressedKeys.value;

    final KeyLabel keyLabel = KeyLabel(
      shortcut,
      highlightCount: pressedKeys.length,
    );

    final (marginLeft, marginRight) = targetMargin;

    /// The size of the jump target itself (without margin).
    final keyLabelSize = keyLabel.calculateSize();

    // The amount of space to reserve for the jump target.
    final reservedSpace = keyLabelSize.width + marginLeft + marginRight;

    final reservedSpaceBefore =
        mainAxisAlignment == MainAxisAlignment.center ? reservedSpace / 2 : 0.0;

    final reservedSpaceAfter = mainAxisAlignment == MainAxisAlignment.center
        ? reservedSpace / 2
        : reservedSpace;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: animationDuration,
          width: showTarget ? 0 : reservedSpaceBefore,
          height: keyLabelSize.height,
        ),
        child,
        AnimatedContainer(
          duration: animationDuration,
          width: showTarget ? 0 : reservedSpaceAfter,
          height: keyLabelSize.height,
        ),
        AnimatedContainer(
          duration: animationDuration,
          margin: showTarget
              ? EdgeInsets.only(left: marginLeft, right: marginRight)
              : const EdgeInsets.all(0),
          width: showTarget ? keyLabelSize.width : 0,
          height: keyLabelSize.height,
          child: showTarget ? keyLabel : null,
        ),
      ],
    );
  }
}
