import 'package:memex_bar/main.dart';
import 'package:memex_ui/memex_ui.dart';
import 'popover.dart';

class OverlayArea extends ReactiveWidget {
  const OverlayArea({super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      if (showOverlay.value)
        Popover(
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notification",
                style:
                    MemexTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                "This is the content of my notification",
                style: MemexTypography.body,
              ),
              Button(
                onPressed: () {
                  print("Notification");
                },
                child: Text("Button"),
              ),
            ],
          ),
        ),
    ];

    grabOverlayInput(children.isNotEmpty);

    return Container(
      // Without color, this doesn't register taps...
      color:
          children.isEmpty ? const Color(0x00000000) : const Color(0x00000000),
      child: Stack(
        alignment: Alignment.topRight,
        children: children,
      ),
    );
  }
}
