import 'package:flutter/services.dart';
import 'package:memex_ui/memex_ui.dart';

abstract class Keymap {
  /// Translate an [event] into actions on an [editor].
  /// Return whether the editor was changed and should be rebuilt.
  bool handle(Editor editor, RawKeyEvent event) => false;
}
