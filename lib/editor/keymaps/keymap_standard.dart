import 'package:flutter/services.dart';
import 'package:memex_ui/editor/keymaps/keymap.dart';
import 'package:memex_ui/memex_ui.dart';

class KeymapStandard implements Keymap {
  const KeymapStandard();

  @override
  bool handle(Editor editor, RawKeyEvent event) {
    if (event.runtimeType == RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyS &&
          event.isControlPressed) {
        // Ignore file save shortcut
        return false;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyO &&
          event.isControlPressed) {
        // Ignore file open shortcut
        return false;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (event.isControlPressed) {
          editor.moveCursorRightOneWord(event.isShiftPressed);
          editor.redrawCaretAndSelection();
          return false;
        } else {
          editor.moveCursorRightOnce(event.isShiftPressed);
          editor.redrawCaretAndSelection();
          return false;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (event.isControlPressed) {
          editor.moveCursorLeftOneWord(event.isShiftPressed);
          editor.redrawCaretAndSelection();
          return false;
        } else {
          editor.moveCursorLeftOnce(event.isShiftPressed);
          editor.redrawCaretAndSelection();
          return false;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        editor.moveCursorDown(event.isShiftPressed);
        editor.redrawCaretAndSelection();
        return false;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        editor.moveCursorUp(event.isShiftPressed);
        editor.redrawCaretAndSelection();
        return false;
      }
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        if (event.isShiftPressed) {
          editor.unindent();
          return true;
        } else {
          editor.indent();
          return true;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (event.isShiftPressed) {
          editor.lineBreakSoft();
          return true;
        } else {
          editor.lineBreakHard();
          return true;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        editor.deleteBackwards();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyZ &&
          event.isControlPressed) {
        if (event.isShiftPressed) {
          editor.redo();
          return true;
        } else {
          editor.undo();
          return true;
        }
      }
      if (event.character != null) {
        editor.append(event.character ?? "?");
        return true;
      }
    }
    return false;
  }
}
