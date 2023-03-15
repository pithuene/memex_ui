import 'package:flutter/services.dart';
import 'package:memex_ui/editor/content_type_popup_menu.dart';
import 'package:memex_ui/editor/content_type_popup_state.dart';
import 'package:memex_ui/editor/keymaps/keymap.dart';
import 'package:memex_ui/editor/piece_path.dart';
import 'package:memex_ui/memex_ui.dart';

class KeymapStandard implements Keymap {
  const KeymapStandard();

  @override
  bool handle(Editor editor, RawKeyEvent event) {
    if (event.runtimeType == RawKeyDownEvent) {
      if (editor.state.contentTypePopupState.isOpen) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          editor.state = editor.state.copyWith(
            contentTypePopupState: editor.state.contentTypePopupState.copyWith(
              index: editor.state.contentTypePopupState.index + 1,
            ),
          );
          editor.redrawContentTypeMenu();
          return false;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          editor.state = editor.state.copyWith(
            contentTypePopupState: editor.state.contentTypePopupState.copyWith(
              index: editor.state.contentTypePopupState.index - 1,
            ),
          );
          editor.redrawContentTypeMenu();
          return false;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          editor.commitUndoState();
          editor.state = editor.state
              .replaceBlockAtPath(
                editor.state.cursor.blockPath,
                (block) => ContentTypePopupMenu
                    .contentTypes[editor.state.contentTypePopupState.index]
                    .block,
              )
              .copyWithCursor(
                blockPath: editor.state.cursor.blockPath,
                piecePath: PiecePath.fromIterable(const [0]),
                offset: 0,
              )
              .copyWith(
                  contentTypePopupState: const ContentTypePopupState.closed());
          return true;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          editor.state = editor.state.copyWith(
            contentTypePopupState: editor.state.contentTypePopupState.copyWith(
              isOpen: false,
              index: 0,
            ),
          );
          editor.redrawContentTypeMenu();
          return false;
        }
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
      if (event.character != null && !event.isControlPressed) {
        editor.append(event.character ?? "?");
        return true;
      }
    }
    return false;
  }
}
