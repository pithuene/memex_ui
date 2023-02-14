library memex_ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

import './state.dart';
export './state.dart';

export './memex_app.dart';
export './table/table.dart';
export './editor/editor.dart';
export './editor/editor_state.dart';
export './editor/editor_view.dart';
export './editor/markdown_serialization.dart';
export './editor/markdown_deserialization.dart';

export './filepicker/filepicker.dart';

class MemexFocusNode extends FocusNode {
  @override
  set onKey(FocusOnKeyCallback? _onKey) {
    super.onKey = (node, event) {
      if (event.runtimeType == RawKeyDownEvent && event.isControlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.keyL) {
          focusInDirection(TraversalDirection.right);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
          node.focusInDirection(TraversalDirection.left);
          return KeyEventResult.handled;
        }
      }
      return _onKey != null ? _onKey(node, event) : KeyEventResult.ignored;
    };
  }
}

abstract class FocusableWidget extends Widget {
  /// Called when the Widget is focused or unfocused.
  void onFocusChange(bool focused);

  /// Called when the Widget is focues and a Key is pressed.
  KeyEventResult onKey(FocusNode node, RawKeyEvent event);
}

/// A row of [FocusableWidget].
/// Manages focus switching between its children.
class FocusRow extends StatelessWidget {
  const FocusRow({
    super.key,
    required this.children,
  });

  final List<FocusableWidget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children
          .map((child) => Flexible(
                fit: FlexFit.tight,
                child: Focus(
                  child: child,
                  onKey: (node, event) {
                    if (event.runtimeType == RawKeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.keyL &&
                          event.isAltPressed) {
                        node.focusInDirection(TraversalDirection.right);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.keyH &&
                          event.isAltPressed) {
                        node.focusInDirection(TraversalDirection.left);
                        return KeyEventResult.handled;
                      }
                    }
                    return child.onKey(node, event);
                  },
                  onFocusChange: (focused) => child.onFocusChange(focused),
                ),
              ))
          .toList(),
    );
  }
}

class TestFocusable extends StatelessWidget implements FocusableWidget {
  Prop<String> content = Prop<String>("");
  Prop<bool> isFocused = Prop<bool>(false);

  @override
  KeyEventResult onKey(FocusNode node, RawKeyEvent event) {
    content.value = content.value + (event.character ?? "");
    return KeyEventResult.handled;
  }

  @override
  void onFocusChange(bool focused) {
    isFocused.value = focused;
  }

  @override
  Widget build(BuildContext context) {
    return $(isFocused, (bool focused) {
      var borderColor = const Color(0xFF000000);
      if (focused) {
        borderColor = MacosTheme.of(context).primaryColor;
      }
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(width: 8, color: borderColor),
            right: BorderSide(
                width: 1, color: MacosTheme.of(context).dividerColor),
          ),
        ),
        child: $(content, (String c) => Text(c)),
      );
    });
  }
}

class TestWidget extends StatelessWidget {
  TestWidget({super.key});

  // Model
  final count = Prop<int>(0);
  late final ReadonlyProp<int> doubleCount =
      ComputedProp(() => 2 * count.value, [count]);

  // Controller
  increment() {
    count.value++;
  }

  // View
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Text("Testing: "),
      $(count, (int x) => Text(x.toString())),
      const Spacer(),
      $(doubleCount, (int x) => Text(x.toString())),
      const Spacer(),
      TestChild(parentCounter: count),
      const Spacer(),
      GestureDetector(
        onTap: increment,
        child: const Text("Increment"),
      ),
    ]);
  }
}

class TestChild extends StatelessWidget {
  TestChild({
    super.key,
    required this.parentCounter,
  });

  final ReadonlyProp<int> parentCounter;
  late final squaredCounter = ComputedProp(
    () => parentCounter.value * parentCounter.value,
    [parentCounter],
  );

  @override
  Widget build(BuildContext context) {
    return $(squaredCounter, (int x) => Text(x.toString()));
  }
}
