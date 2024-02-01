import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart';

class MemexTypography {
  static const String fontFamily = "Inter";
  static const String fontFamilyMonospace = "JetBrainsMono Nerd Font";
  static const double baseFontSize = 16;

  static const TextStyle code = TextStyle(
    fontFamily: fontFamilyMonospace,
    fontWeight: FontWeight.normal,
    fontSize: baseFontSize * 0.8,
    color: MemexColor.text,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.normal,
    fontSize: baseFontSize,
    color: MemexColor.text,
  );

  static const TextStyle extraLargeTitle = heading1;
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: baseFontSize * 2.8,
    color: MemexColor.text,
  );

  static const TextStyle largeTitle = heading2;
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: baseFontSize * 2.2,
    color: MemexColor.text,
    letterSpacing: -0.03 * baseFontSize,
  );

  static const TextStyle title = heading3;
  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: baseFontSize * 1.4,
    color: MemexColor.text,
    letterSpacing: -0.02 * baseFontSize,
  );

  static const TextStyle subtitle = heading4;
  static const TextStyle heading4 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: baseFontSize * 1.1,
    color: MemexColor.text,
    letterSpacing: -0.012 * baseFontSize,
  );
}
