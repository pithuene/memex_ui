import 'package:macos_ui/macos_ui.dart';
import 'package:memex_ui/memex_ui.dart';

class Slider extends ReactiveWidget {
  final Prop<double> value;

  /// Whether the slider is discrete or continuous.
  ///
  /// Continuous sliders have a thumb that can be dragged anywhere along the track.
  /// Discrete sliders have a thumb that can only be dragged to the tick marks.
  ///
  /// [splits] will only be considered if this is true.
  final bool discrete;

  /// The minimum value of this slider
  final double min;

  /// The maximum value of this slider
  final double max;

  /// The number of discrete splits when using [discrete] mode.
  ///
  /// This includes the split at [min] and [max]
  final int splits;

  const Slider(
    this.value, {
    super.key,
    this.discrete = false,
    this.splits = 15,
    this.min = 0.0,
    this.max = 1.0,
  });

  @override
  Widget build(BuildContext context) => MacosSlider(
        value: value.value,
        onChanged: (newValue) => value.value = newValue,
        discrete: discrete,
        splits: splits,
        min: min,
        max: max,
      );
}
