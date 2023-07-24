import 'main.dart';
import 'popover.dart';
import 'package:memex_ui/memex_ui.dart';

abstract class BarModule extends ReactiveWidget {
  final Prop<bool> isShown = Prop(false);
  double get width;
  BarModule({super.key});

  Widget buildBarEntry(BuildContext context, bool isHovered);
  Widget buildOverlay(BuildContext context);

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: barHeight,
            child: GestureDetector(
              onTap: () => isShown.value = !isShown.value,
              child: HoverDetector(
                builder: (context, isHovered, _) =>
                    buildBarEntry(context, isHovered),
              ),
            ),
          ),
          if (isShown.value)
            Positioned(
              top: barHeight,
              right: 0,
              width: width,
              child: Popover(buildOverlay(context)),
            ),
        ],
      );
}
