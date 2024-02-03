import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:memex_bar/bar.dart';
import 'package:memex_bar/overlay_area.dart';
import 'package:memex_ui/memex_ui.dart';

const barHeight = 32.0;

Prop<bool> showOverlay = Prop(false);
Prop<bool> showWifi = Prop(false);
Prop<bool> wifiOn = Prop(true);

const inputRegionChannel = MethodChannel('bar.memex/input_region');

void grabOverlayInput(bool grab) {
  inputRegionChannel.invokeMethod("grabOverlayInput", {"grab": grab});
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App(
      appName: "Memex Bar",
      backgroundColor: MemexColor.transparent,
      builder: (context, _) => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: barHeight,
            decoration: const BoxDecoration(
              color: MemexColor.white,
              border: Border(
                bottom: BorderSide(color: CupertinoColors.separator),
              ),
            ),
            child: const Bar(),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                print("clicked");
                showOverlay.value = false;
              },
              child: const OverlayArea(),
            ),
          ),
        ],
      ),
    );
  }
}
