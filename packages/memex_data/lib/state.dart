import 'package:flutter/widgets.dart';
import 'package:memex_data/memex_data.dart';

extension StateFromContext on BuildContext {
  M state<M>() {
    BuildContext context = this;
    M? result;
    StateProviderState? provider;
    while (result == null) {
      provider = context.findAncestorStateOfType<StateProviderState>();
      if (provider == null) {
        break;
      }
      result = provider.state.firstWhere(
        (s) => s is M,
        orElse: () => null,
      ) as M?;
      if (result != null) {
        return result;
      }
      context = provider.context;
    }
    throw Exception("No state provider $M found in the widget tree.");
  }
}

// TODO: Lifecycle methods?
class StateProvider extends StatefulWidget {
  final WidgetBuilder builder;
  final Iterable models;

  const StateProvider({
    super.key,
    required this.models,
    required this.builder,
  });

  @override
  StateProviderState createState() => StateProviderState();
}

class StateProviderState extends State<StateProvider> {
  final List state = [];

  @override
  void initState() {
    super.initState();
    state.addAll(widget.models.map((model) => model()));
  }

  @override
  Widget build(BuildContext context) => ReactiveBuilder.context(widget.builder);
}
