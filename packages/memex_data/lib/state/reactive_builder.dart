import 'package:flutter/widgets.dart';
import './state.dart';

class ReactiveBuilder extends StatefulWidget {
  final Widget Function() builder;
  const ReactiveBuilder(this.builder, {super.key});

  @override
  State<StatefulWidget> createState() => _ReactiveBuilderState();
}

class _ReactiveBuilderState extends State<ReactiveBuilder>
    with ReactiveListener {
  Widget? cache;

  @override
  void onDependencyChange() {
    //WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) setState(() => cache = null);
    //});
  }

  @override
  void dispose() {
    removeAllListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*if (cache == null) {
      removeAllListeners();
      executeInContext(() {
        cache = widget.builder();
      });
    }*/
    executeInContext(() {
      cache = widget.builder();
    });
    return cache!;
  }
}
