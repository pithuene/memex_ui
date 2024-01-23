import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:memex_ui/memex_ui.dart';

String memexAppName = "Memex App";

class App extends StatelessWidget {
  App({
    super.key,
    required String appName,
    this.sidebar,
    this.endSidebar,
    this.toolBar,
    required this.builder,
  }) {
    memexAppName = appName;
  }

  final ScrollableWidgetBuilder builder;
  final Sidebar? sidebar;
  final Sidebar? endSidebar;
  final ToolBar? toolBar;

  @override
  Widget build(BuildContext context) => Portal(
        child: JumpFocusController(
          focusNode: FocusNode()..requestFocus(),
          child: MacosApp(
            debugShowCheckedModeBanner: false,
            shortcuts: const {},
            builder: (context, child) => MacosTheme(
              data: MacosThemeData(
                canvasColor: MemexColor.white,
                typography: MacosTypography(
                  color: MemexColor.text,
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
                endSidebar: endSidebar,
                disableWallpaperTinting: true,
                child: MacosScaffold(
                  toolBar: toolBar,
                  children: [ContentArea(builder: builder)],
                ),
              ),
            ),
          ),
        ),
      );
}
