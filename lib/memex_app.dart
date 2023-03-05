import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.builder,
    this.sidebar,
    this.toolBar,
    this.fontFamily = "Inter",
    this.baseFontSize = 14,
    this.textColor = Colors.black,
  });

  final ScrollableWidgetBuilder builder;
  final Sidebar? sidebar;
  final ToolBar? toolBar;

  final String fontFamily;
  final double baseFontSize;
  final Color textColor;

  @override
  Widget build(BuildContext context) => MacosApp(
        home: MacosTheme(
          data: MacosThemeData(
            typography: MacosTypography(
              color: Colors.black,
              body: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w400,
                fontSize: baseFontSize,
                color: textColor,
              ),
              headline: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w400,
                fontSize: baseFontSize,
              ),
              title3: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 1.1,
                color: textColor,
                letterSpacing: -0.012 * baseFontSize,
              ),
              title2: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 1.4,
                color: textColor,
                letterSpacing: -0.02 * baseFontSize,
              ),
              title1: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 2.2,
                color: textColor,
                letterSpacing: -0.03 * baseFontSize,
              ),
              largeTitle: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 2.8,
                color: textColor,
              ),
            ),
          ),
          child: MacosWindow(
            sidebar: sidebar,
            child: MacosScaffold(
              toolBar: toolBar,
              children: [ContentArea(builder: builder)],
            ),
          ),
        ),
      );
}
