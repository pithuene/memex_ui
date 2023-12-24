class FixedLengthStack<T> {
  final List<T> _stack = [];
  final int _maxLength;
  FixedLengthStack(this._maxLength);

  void push(T state) {
    if (_stack.length == _maxLength) {
      _stack.removeAt(0);
    }
    _stack.add(state);
  }

  T? pop() {
    if (_stack.isEmpty) return null;
    return _stack.removeLast();
  }

  void clear() {
    _stack.clear();
  }

  bool get isEmpty => _stack.isEmpty;
}
