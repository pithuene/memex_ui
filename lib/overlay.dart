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
    builder: (context) => ColoredBox(
      color: const Color(0x55000000),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8.0,
          sigmaY: 8.0,
        ),
        child: Center(child: builder(context, overlayEntry!)),
      ),
    ),
  );
  overlayState.insert(overlayEntry);
}
