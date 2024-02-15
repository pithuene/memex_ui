import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
    this.backgroundColor = MemexColor.white,
    this.shortcuts = const {},
    required this.builder,
  }) {
    memexAppName = appName;
  }

  final ScrollableWidgetBuilder builder;

  final Sidebar? sidebar;
  final Sidebar? endSidebar;
  final ToolBar? toolBar;
  final Color? backgroundColor;
  final Map<LogicalKeySet, Intent> shortcuts;

  @override
  Widget build(BuildContext context) => Portal(
        child: JumpFocusController(
          focusNode: FocusNode()..requestFocus(),
          child: MacosApp(
            debugShowCheckedModeBanner: false,
            shortcuts: shortcuts,
            theme: MacosThemeData(
              canvasColor: backgroundColor,
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
            builder: (context, _) => MacosWindow(
              sidebar: sidebar,
              endSidebar: endSidebar,
              disableWallpaperTinting: true,
              child: MacosScaffold(
                toolBar: toolBar,
                children: [
                  ContentArea(
                    builder: (context, scrollController) => CupertinoTabView(
                      navigatorKey: _navigatorKey,
                      builder: (context) => builder(context, scrollController)
                          .backgroundColor(MemexColor.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  static App of(BuildContext context) {
    return context.findAncestorWidgetOfExactType<App>()!;
  }

  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  static NavigatorState get navigator => _navigatorKey.currentState!;
}
