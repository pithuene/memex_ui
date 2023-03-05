import 'package:memex_ui/memex_ui.dart';

/// A fixed length stack of [EditorState]s used in the undo / redo mechanism.
class EditorStateStack {
  final List<EditorState> _stack = [];
  final int _maxLength;
  EditorStateStack(this._maxLength);

  void push(EditorState state) {
    if (_stack.length == _maxLength) {
      _stack.removeAt(0);
    }
    _stack.add(state);
  }

  EditorState? pop() {
    if (_stack.isEmpty) return null;
    return _stack.removeLast();
  }

  void clear() {
    _stack.clear();
  }

  bool get isEmpty => _stack.isEmpty;
}
