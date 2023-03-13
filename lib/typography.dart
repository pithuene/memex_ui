import 'package:flutter/material.dart';

class MemexTypography {
  static String fontFamily = "Inter";
  static String fontFamilyMonospace = "JetBrainsMono Nerd Font";
  static double baseFontSize = 16;
  static Color textColor = const Color(0xFF000000);
  static Color selectionColor = const Color(0x55007aFF);

  static TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.normal,
    fontSize: baseFontSize,
    color: textColor,
  );

  static TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: baseFontSize * 2.8,
    color: textColor,
  );

  static TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: baseFontSize * 2.2,
    color: textColor,
    letterSpacing: -0.03 * baseFontSize,
  );

  static TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: baseFontSize * 1.4,
    color: textColor,
    letterSpacing: -0.02 * baseFontSize,
  );

  static TextStyle heading4 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: baseFontSize * 1.1,
    color: textColor,
    letterSpacing: -0.012 * baseFontSize,
  );
}
