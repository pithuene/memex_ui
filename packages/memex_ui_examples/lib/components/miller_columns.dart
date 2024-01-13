import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/miller_columns/miller_columns.dart';
import 'package:memex_ui/miller_columns/directory_explorer.dart';
import 'package:memex_ui_examples/components.dart';

class StoryMillerColumnsDefault extends Story {
  static Prop<double> value = Prop(0.5);

  StoryMillerColumnsDefault()
      : super(
          name: "Default",
          knobs: [KnobSlider("Value", value)],
        );

  @override
  Widget build(BuildContext context) => DirectoryExplorer(
        showHidden: false,
      );
}

ComponentExample componentMillerColumns() => ComponentExample(
      name: "Miller Columns",
      stories: [
        StoryMillerColumnsDefault(),
      ],
    );
