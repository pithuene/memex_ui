import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/knobs/knob.dart';

class KnobSlider extends Knob {
  final Prop<double> value;
  final bool discrete;
  final double min;
  final double max;
  final int splits;

  KnobSlider(
    super.label,
    this.value, {
    this.discrete = false,
    this.splits = 15,
    this.min = 0.0,
    this.max = 1.0,
  });

  @override
  Widget build(BuildContext context) => Slider(value);
}
