import 'package:macos_ui/macos_ui.dart';
import 'package:flutter/widgets.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.builder,
    this.sidebar,
  });

  final ScrollableWidgetBuilder builder;
  final Sidebar? sidebar;

  @override
  Widget build(BuildContext context) => MacosApp(
        home: MacosWindow(
          sidebar: sidebar,
          child: MacosScaffold(
            toolBar: ToolBar(
              title: Text(
                "Test",
                style: const TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            children: [ContentArea(builder: builder)],
          ),
        ),
      );
}
