import 'package:memex_ui/memex_ui.dart';

class MemexBorder {
  static const BorderRadius radius = BorderRadius.all(
    Radius.circular(8),
  );

  static const BorderSide side = BorderSide(
    color: MemexColor.grid,
    width: 1,
  );

  static Border all = Border.fromBorderSide(
    side.copyWith(
      strokeAlign: BorderSide.strokeAlignOutside,
    ),
  );
}
