import 'package:memex_ui/memex_ui.dart';

class JumpFocusTarget extends StatefulWidget {
  const JumpFocusTarget({
    Key? key,
    this.usePersistentShortcut = false,
    this.disabled = false,
    required this.onJump,
    required this.builder,
  }) : super(key: key);

  final Widget Function(BuildContext, Shortcut?, bool) builder;
  final VoidCallback onJump;

  /// Disables the widget, preventing the allocation of a shortcut.
  final bool disabled;

  /// Use the same keybinding for the entire lifetime of the widget.
  /// Normally, a new binding is created every time focus mode is entered.
  final bool usePersistentShortcut;

  @override
  _JumpFocusTargetState createState() => _JumpFocusTargetState();
}

class _JumpFocusTargetState extends State<JumpFocusTarget> {
  Shortcut? _key;
  JumpFocusControllerState? _controller;

  void _dynamicShortcut() {
    if (_controller!.isJumping.value) {
      setState(() {
        _key = _controller!.registerBinding(() {
          setState(() {});
          widget.onJump();
        });
      });
    } else {
      if (_key != null) {
        _controller!.unregisterBinding(_key!);
        if (mounted) {
          setState(() {
            _key = null;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (!widget.disabled) {
      _controller = JumpFocusControllerState.of(context)!;
      if (widget.usePersistentShortcut) {
        _key = _controller!.registerBinding(() {
          setState(() {});
          widget.onJump();
        });
      } else {
        _controller!.isJumping.addListener(_dynamicShortcut);
      }
    }
  }

  @override
  void dispose() {
    if (!widget.disabled) {
      if (_key != null) _controller!.unregisterBinding(_key!);
      _controller!.isJumping.removeListener(_dynamicShortcut);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.disabled) {
      return widget.builder(context, null, false);
    }

    final isJumping = JumpFocusControllerState.of(context)!.isJumping;
    final pressedKeys = JumpFocusControllerState.of(context)!.pressedKeys;
    return ReactiveBuilder(() {
      final isSelectable = _key != null &&
          isJumping.value &&
          pressedKeys.value.length <= _key!.length &&
          _key!.sublist(0, pressedKeys.value.length) == pressedKeys.value;

      return widget.builder(context, _key, isSelectable);
    });
  }
}
