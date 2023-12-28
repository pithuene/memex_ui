import 'package:flutter/services.dart';
import 'package:memex_ui/memex_ui.dart';

typedef Shortcut = IList<LogicalKeyboardKey>;

class JumpFocusController extends StatefulWidget {
  const JumpFocusController({
    Key? key,
    required this.child,
    required this.focusNode,
  }) : super(key: key);

  final Widget child;
  final FocusNode focusNode;

  @override
  JumpFocusControllerState createState() => JumpFocusControllerState();
}

class JumpFocusControllerState extends State<JumpFocusController> {
  late final Prop<bool> isJumping = Prop(false);

  final Prop<Shortcut> pressedKeys = Prop(<LogicalKeyboardKey>[].lockUnsafe);

  static const LogicalKeyboardKey focusKey = LogicalKeyboardKey.keyF;

  late Set<Shortcut> freeKeys = <Shortcut>{};

  final Map<Shortcut, VoidCallback> _bindings = {};

  @override
  void initState() {
    super.initState();

    List<LogicalKeyboardKey> keyList = [
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyG,
      LogicalKeyboardKey.keyH,
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyK,
      LogicalKeyboardKey.keyL,
      LogicalKeyboardKey.keyQ,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyE,
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.keyT,
      LogicalKeyboardKey.keyU,
      LogicalKeyboardKey.keyI,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyX,
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.keyB,
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.keyM,
    ];

    for (final key1 in keyList) {
      for (final key2 in keyList) {
        freeKeys.add([key1, key2].lockUnsafe);
      }
    }
  }

  Shortcut registerBinding(VoidCallback callback) {
    final key = freeKeys.first;
    freeKeys.remove(key);
    _bindings[key] = callback;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    return key;
  }

  void unregisterBinding(Shortcut key) {
    freeKeys.add(key);
    _bindings.remove(key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  JumpFocusControllerState();

  static JumpFocusControllerState? of(BuildContext context) {
    return context.findAncestorStateOfType<JumpFocusControllerState>();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: widget.focusNode,
      skipTraversal: true,
      // canRequestFocus: false,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is! RawKeyDownEvent) {
          return KeyEventResult.ignored;
        }

        if (!isJumping.value && event.logicalKey == focusKey) {
          isJumping.value = true;
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.escape) {
          isJumping.value = false;
          pressedKeys.value = pressedKeys.value.clear();
          return KeyEventResult.handled;
        }

        if (isJumping.value) {
          pressedKeys.value = pressedKeys.value.add(event.logicalKey);
          final action = _bindings[pressedKeys.value];
          if (action != null) {
            action();
            pressedKeys.value = pressedKeys.value.clear();
            isJumping.value = false;
          }

          // Check if the pressed keys are a prefix of any of the registered
          // shortcuts.
          bool isPrefix = false;
          for (final key in _bindings.keys) {
            if (key.sublist(0, pressedKeys.value.length) == pressedKeys.value) {
              isPrefix = true;
              break;
            }
          }

          // Input cannot be extended to a valid shortcut.
          if (!isPrefix) {
            pressedKeys.value = pressedKeys.value.clear();
            isJumping.value = false;
          }

          return KeyEventResult.handled;
        } else {
          return KeyEventResult.ignored;
        }
      },
      child: widget.child,
    );
  }
}
