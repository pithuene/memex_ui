import 'package:memex_bar/main.dart';
import 'package:memex_bar/modules/datetime.dart';
import 'package:memex_bar/modules/sway.dart';
import 'modules/wifi.dart';
import 'package:memex_ui/memex_ui.dart';

class Bar extends ReactiveWidget {
  const Bar({super.key});
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 16),
          const SwayModule(),
          const Spacer(),
          WifiModule(),
          const SizedBox(width: 24),
          const MemexIcon(CupertinoIcons.volume_up),
          const SizedBox(width: 24),
          const MemexIcon(CupertinoIcons.mic_off),
          const SizedBox(width: 24),
          const MemexIcon(CupertinoIcons.brightness),
          Text(
            " 50%",
            style: MemexTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 24),
          const MemexIcon(CupertinoIcons.battery_full, size: 24),
          Text(
            " 100%",
            style: MemexTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 24),
          DateTimeModule(),
          Button(
            onPressed: () {
              print("Test");
              showOverlay.value = !showOverlay.value;
            },
            child: const Text("Grab"),
          ),
        ],
      );
}
