import 'package:flutter/foundation.dart';

@immutable
class ContentTypePopupState {
  final bool isOpen;
  final int index;
  const ContentTypePopupState({
    required this.isOpen,
    required this.index,
  });

  const ContentTypePopupState.closed()
      : isOpen = false,
        index = 0;

  const ContentTypePopupState.opened()
      : isOpen = true,
        index = 0;

  ContentTypePopupState copyWith({
    bool? isOpen,
    int? index,
  }) {
    return ContentTypePopupState(
      isOpen: isOpen ?? this.isOpen,
      index: index ?? this.index,
    );
  }
}
