import 'package:memex_ui/memex_ui.dart';
export 'knob_switch.dart';
export 'knob_slider.dart';

abstract class Knob {
  final String label;
  const Knob(this.label);
  Widget build(BuildContext context);
}
