import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart';

void openOverlay(
  BuildContext context,
  Widget Function(BuildContext, OverlayEntry) builder,
) {
  OverlayState overlayState = Overlay.of(context)!;
  OverlayEntry? overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => JumpFocusController(
      focusNode: FocusNode()..requestFocus(),
      // Capture all click events so that the overlay can be closed when the user clicks outside of it.
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Container(
            decoration: const BoxDecoration(boxShadow: [
              BoxShadow(
                blurRadius: 90,
                spreadRadius: 30,
                offset: Offset(0, 20),
                color: Color(0x88000000),
              )
            ]),
            child: builder(context, overlayEntry!),
          ),
        ),
      ),
    ),
  );
  overlayState.insert(overlayEntry);
}
