import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components.dart';

class ReactiveWidgetWithState extends ReactiveWidget {
  final Prop<int> state = Prop(0);
  ReactiveWidgetWithState({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          state.value += 1;
        },
        child: Text(state.value.toString())
            .padding(all: 20)
            .backgroundColor(MemexColor.transparent),
      );
}

class ExternalStateModel {
  final Prop<int> state = Prop(0);
}

class ReactiveWidgetUsingStateProvider extends ReactiveWidget {
  const ReactiveWidgetUsingStateProvider({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          context.state<ExternalStateModel>().state.value += 1;
        },
        child: Text(context.state<ExternalStateModel>().state.value.toString())
            .padding(all: 20)
            .backgroundColor(MemexColor.transparent),
      );
}

class StoryStateDefault extends Story {
  StoryStateDefault({
    super.name = "Default",
  });

  @override
  Widget build(BuildContext context) =>
      HoverDetector(builder: (context, hovered, _) => ReactiveWidgetWithState())
          .center();
}

class StoryStateResetOnParentRebuild extends Story {
  StoryStateResetOnParentRebuild({
    super.name = "In ReactiveWidget",
  });

  Widget buildExample(BuildContext context, String title, String description,
      WidgetBuilder child) {
    return [
      title.toTitle(),
      const SizedBox(height: 10),
      description.toText().textAlignment(TextAlign.justify).width(250),
      const SizedBox(height: 10),
      HoverDetector(
        builder: (context, hovered, _) => child(context)
            .outlined()
            .elevation(
              hovered ? 10 : 2,
              borderRadius: BorderRadius.circular(8),
            )
            .backgroundColor(MemexColor.white)
            .animate(
              const Duration(milliseconds: 100),
              Curves.easeOutCubic,
            ),
      ).center().width(250),
    ].toColumn(crossAxisAlignment: CrossAxisAlignment.start).padding(all: 20);
  }

  @override
  Widget build(BuildContext context) => [
        buildExample(
          context,
          "State in ReactiveWidget",
          "State should not be declared inside a ReactiveWidget. "
              "When the ReactiveWidget is rebuilt, the state will be reinitialized. "
              "In this example, clicking the widget will increment the state, "
              "but when the mouse moves away from the widget, it will be rebuilt, resetting it's state",
          (_) => ReactiveWidgetWithState(),
        ),
        buildExample(
          context,
          "State in StateProvider",
          "Instead, create a class to hold the state and use a StateProvider to place it in the widget tree. "
              "The state will be persisted even when the widget is rebuilt. "
              "You can access the state using the context.state<M>() method.",
          (_) => StateProvider(
            models: [() => ExternalStateModel()],
            builder: (context) => const ReactiveWidgetUsingStateProvider(),
          ),
        ),
      ].toRow();
}

class ExampleConsumerWidget extends ReactiveWidget {
  const ExampleConsumerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return "Hello World ${context.state<ExampleModel>().state.value.toString()}"
        .toText();
  }
}

class ExampleModel {
  final Prop<int> state = Prop(0);
}

class ExampleModel2 {
  final Prop<int> moreState = Prop(0);
}

class StoryStateProvider extends Story {
  StoryStateProvider({
    super.name = "State Provider",
  });

  @override
  Widget build(BuildContext context) => StateProvider(
        models: [() => ExampleModel2(), () => ExampleModel()],
        builder: (context) => [
          "Hello World".toTitle(),
          const ExampleConsumerWidget(),
          const SizedBox(height: 3),
          Button(
            onPressed: () {
              context.state<ExampleModel>().state.value += 1;
            },
            child: "Increment".toText(),
          ),
        ]
            .toColumn(
              separator: const SizedBox(height: 3),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
            )
            .padding(all: 16)
            .outlined()
            .elevation(6, borderRadius: BorderRadius.circular(6))
            .center(),
      );
}

ComponentExample componentState() => ComponentExample(
      name: "State",
      stories: [
        StoryStateDefault(),
        StoryStateResetOnParentRebuild(),
        StoryStateProvider(),
      ],
    );
