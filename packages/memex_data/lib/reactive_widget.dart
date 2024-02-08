import 'package:flutter/widgets.dart';
import './reactive_listener.dart';

abstract class ReactiveWidget extends StatefulWidget {
  const ReactiveWidget({super.key});

  Widget build(BuildContext context);

  @override
  State<StatefulWidget> createState() => _ReactiveWidgetState();
}

class _ReactiveWidgetState extends State<ReactiveWidget> with ReactiveListener {
  @override
  void onDependencyChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    removeAllListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    removeAllListeners();
    Widget? result;
    executeInContext(() {
      result = widget.build(context);
    });
    return result!;
  }
}
