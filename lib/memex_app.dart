import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:memex_ui/typography.dart';

String memexAppName = "Memex App";

class App extends StatelessWidget {
  App({
    super.key,
    required this.builder,
    this.sidebar,
    this.toolBar,
    required String appName,
  }) {
    memexAppName = appName;
  }

  final ScrollableWidgetBuilder builder;
  final Sidebar? sidebar;
  final ToolBar? toolBar;

  @override
  Widget build(BuildContext context) => Portal(
        child: MacosApp(
          shortcuts: const {},
          home: MacosTheme(
            data: MacosThemeData(
              typography: MacosTypography(
                color: Colors.black,
                body: MemexTypography.body,
                headline: MemexTypography.body,
                title3: MemexTypography.heading4,
                title2: MemexTypography.heading3,
                title1: MemexTypography.heading2,
                largeTitle: MemexTypography.heading1,
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
        ),
      );
}
