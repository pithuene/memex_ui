import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/knobs/knob.dart';

class KnobSwitch extends Knob {
  KnobSwitch(
    super.label,
    this.value,
  );
  final Prop<bool> value;

  @override
  Widget build(BuildContext context) => Switch(value);
}
