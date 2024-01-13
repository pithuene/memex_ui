import 'package:memex_ui/memex_ui.dart';

class MemexBorder {
  static const BorderSide side = BorderSide(
    color: MemexColor.grid,
    strokeAlign: BorderSide.strokeAlignOutside,
    width: 1,
  );

  static const Border all = Border.fromBorderSide(side);
}
