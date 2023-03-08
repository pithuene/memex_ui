import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:memex_ui/typography.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.builder,
    this.sidebar,
    this.toolBar,
  });

  final ScrollableWidgetBuilder builder;
  final Sidebar? sidebar;
  final ToolBar? toolBar;

  @override
  Widget build(BuildContext context) => MacosApp(
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
      );
}
