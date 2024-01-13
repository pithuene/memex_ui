import 'package:flutter/material.dart';
import 'package:memex_ui/memex_ui.dart';

void openOverlay(
  BuildContext context,
  Widget Function(BuildContext, OverlayEntry) builder,
) {
  OverlayState overlayState = Overlay.of(context);
  OverlayEntry? overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => JumpFocusController(
      focusNode: FocusNode()..requestFocus(),
      child: builder(context, overlayEntry!)
          .elevation(30.0)
          .center()
          // Capture all click events so that the overlay can be closed when the user clicks outside of it.
          .backgroundColor(Colors.transparent),
    ),
  );
  overlayState.insert(overlayEntry);
}
