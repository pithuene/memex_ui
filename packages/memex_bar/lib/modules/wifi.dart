import 'package:memex_ui/memex_ui.dart';
import '../bar_module.dart';
import 'package:flutter/material.dart' as material;

class WifiModule extends BarModule {
  static final Prop<bool> wifiOn = Prop(true);

  WifiModule({super.key});

  @override
  double get width => 350;

  @override
  Widget buildBarEntry(
    BuildContext context,
    bool isHovered,
  ) =>
      const MemexIcon(
        CupertinoIcons.wifi,
        size: MemexTypography.baseFontSize * 1.1,
      ).padding(all: 4).highlight(visible: isHovered || isShown.value);

  @override
  Widget buildOverlay(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Wi-Fi ",
                style:
                    MemexTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Switch(wifiOn),
            ],
          ),
          const material.Divider(),
          Text(
            "This is the content of my notification",
            style: MemexTypography.body,
          ),
          material.MaterialButton(
            onPressed: () {
              print("Notification");
            },
            child: Text("Button"),
          ),
        ],
      );
}
