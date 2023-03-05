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

  // Non reversable actions
  void moveCursorRightOnce(bool isSelecting) =>
      state = state.moveCursorRightOnce(isSelecting);
  void moveCursorLeftOnce(bool isSelecting) =>
      state = state.moveCursorLeftOnce(isSelecting);
  void moveCursorRightOneWord(bool isSelecting) =>
      state = state.moveCursorRightOneWord(isSelecting);
  void moveCursorLeftOneWord(bool isSelecting) =>
      state = state.moveCursorLeftOneWord(isSelecting);

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

  // TODO: Name newBlock?
  void newLine() => _performReversableAction(state.newLine());

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
}
