import 'dart:async';
import 'package:memex_ui/editor/state_stack.dart';

import './editor_state.dart';

class Editor {
  EditorState state;
  Editor(this.state);

  EditorStateStack undoStack = EditorStateStack(100);
  EditorStateStack redoStack = EditorStateStack(100);

  /// Emits every time the cursor or selection changes.
  /// Used for rebuilding.
  StreamController<void> onCursorChange = StreamController.broadcast();

  /// Emits when an internal action needs to trigger a rebuild.
  /// The view widget should subscribe to this and rebuild
  /// the editor on events.
  StreamController<void> onRebuild = StreamController.broadcast();

  /// Emits when the [ContentTypePopupMenu] needs to be rebuilt.
  StreamController<void> onContentTypeMenuChange = StreamController.broadcast();

  /// Trigger a rebuild of the editor.
  /// Call this after editing the [EditorState] from outside
  /// the [Editor] operations to show changes.
  void rebuild() {
    onRebuild.sink.add(null);
  }

  void redrawCaretAndSelection() {
    onCursorChange.sink.add(null);
  }

  void redrawContentTypeMenu() {
    onContentTypeMenuChange.sink.add(null);
  }

  // Non reversable actions
  void moveCursorRightOnce(bool isSelecting) =>
      state = state.moveCursorRightOnce(isSelecting);
  void moveCursorLeftOnce(bool isSelecting) =>
      state = state.moveCursorLeftOnce(isSelecting);
  void moveCursorRightOneWord(bool isSelecting) =>
      state = state.moveCursorRightOneWord(isSelecting);
  void moveCursorLeftOneWord(bool isSelecting) =>
      state = state.moveCursorLeftOneWord(isSelecting);

  void moveCursorDown(bool isSelecting) =>
      state = state.moveCursorDown(isSelecting);
  void moveCursorUp(bool isSelecting) =>
      state = state.moveCursorUp(isSelecting);

  /// Store the current state as a checkpoint in the undo system.
  /// Call this before editing the [EditorState] through something
  /// outside of the operations on [Editor].
  void commitUndoState() {
    undoStack.push(state);
    redoStack.clear();
  }

  void _performReversableAction(EditorState newState) {
    undoStack.push(state);
    redoStack.clear();
    state = newState;
  }

  // Reversable actions
  void append(String content) =>
      _performReversableAction(state.append(content));

  void indent() => _performReversableAction(state.indent());

  void unindent() => _performReversableAction(state.unindent());

  void deleteBackwards() => _performReversableAction(state.deleteBackwards());

  void lineBreakHard() => _performReversableAction(state.lineBreakHard());
  void lineBreakSoft() => _performReversableAction(state.lineBreakSoft());

  // Undo / Redo
  void undo() {
    if (undoStack.isEmpty) return;
    redoStack.push(state);
    state = undoStack.pop()!;
  }

  void redo() {
    if (redoStack.isEmpty) return;
    undoStack.push(state);
    state = redoStack.pop()!;
  }

  /// Emits when a link should be opened.
  StreamController<String> onHandleLink = StreamController.broadcast();

  void openLink(String target) => onHandleLink.sink.add(target);
}
