import 'package:flutter/widgets.dart';
import './reactive_listener.dart';

class ReactiveBuilder extends StatefulWidget {
  final Widget Function()? builder;
  final WidgetBuilder? contextBuilder;

  const ReactiveBuilder(Widget Function() builder, {super.key})
      : builder = builder,
        contextBuilder = null;

  const ReactiveBuilder.context(WidgetBuilder builder, {super.key})
      : builder = null,
        contextBuilder = builder;

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
        cache = widget.contextBuilder != null
            ? widget.contextBuilder!(context)
            : widget.builder!();
      });
    }*/
    executeInContext(() {
      cache = widget.contextBuilder != null
          ? widget.contextBuilder!(context)
          : widget.builder!();
    });
    return cache!;
  }
}
