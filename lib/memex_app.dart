import 'package:macos_ui/macos_ui.dart';
import 'package:flutter/widgets.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => MacosApp(
        home: MacosWindow(
          child: child,
        ),
      );
}
