import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:memex_ui/memex_ui.dart';

class Switch extends ReactiveWidget {
  final Prop<bool> value;
  const Switch(this.value, {super.key});

  @override
  Widget build(BuildContext context) => MacosSwitch(
        value: value.value,
        onChanged: (newValue) => value.value = newValue,
      );
}
