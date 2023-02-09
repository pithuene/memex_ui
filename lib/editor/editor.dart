import 'dart:async';
import './editor_state.dart';

class Editor {
  EditorState state;
  Editor(this.state);

  List<EditorState> undoStack = [];
  List<EditorState> redoStack = [];

  /// Emits every time the cursor or selection changes.
  /// Used for rebuilding.
  StreamController<void> onCursorChange = StreamController.broadcast();

  // Non reversable actions
  void moveCursorRightOnce(bool isSelecting) =>
      state = state.moveCursorRightOnce(isSelecting);
  void moveCursorLeftOnce() => state = state.moveCursorLeftOnce();

  void _performReversableAction(EditorState newState) {
    undoStack.add(state);
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
    redoStack.add(state);
    state = undoStack.removeLast();
  }

  void redo() {
    if (redoStack.isEmpty) return;
    undoStack.add(state);
    state = redoStack.removeLast();
  }
}
