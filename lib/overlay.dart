import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void openOverlay(
  BuildContext context,
  Widget Function(BuildContext, OverlayEntry) builder,
) {
  OverlayState overlayState = Overlay.of(context)!;
  OverlayEntry? overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => Center(
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
  );
  overlayState.insert(overlayEntry);
}
