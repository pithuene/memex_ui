import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'modules/wifi.dart';
import 'package:memex_ui/memex_ui.dart';
import 'popover.dart';

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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: MemexColor.white,
              border: Border(
                bottom: BorderSide(color: CupertinoColors.separator),
              ),
            ),
            child: Bar(),
          ),
          Expanded(
            child: GestureDetector(
                onTap: () {
                  print("clicked");
                  showOverlay.value = false;
                },
                child: OverlayArea()),
          ),
        ],
      ),
    );
  }
}

class Bar extends ReactiveWidget {
  const Bar({super.key});
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 16),
          Text(
            "Window Title",
            style: MemexTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          WifiModule(),
          const SizedBox(width: 24),
          MemexIcon(CupertinoIcons.volume_up),
          const SizedBox(width: 24),
          MemexIcon(CupertinoIcons.mic_off),
          const SizedBox(width: 24),
          MemexIcon(CupertinoIcons.brightness),
          Text(
            " 50%",
            style: MemexTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 24),
          MemexIcon(CupertinoIcons.battery_full),
          Text(
            " 100%",
            style: MemexTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 24),
          Text(
            DateTime.now().toLocal().toString(),
            style: MemexTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          material.MaterialButton(
            onPressed: () {
              print("Test");
              showOverlay.value = !showOverlay.value;
            },
            child: Text("Grab"),
          ),
        ],
      );
}

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
              SizedBox(height: 4),
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
          ),
        ),
    ];

    grabOverlayInput(children.isNotEmpty);

    return Container(
      // Without color, this doesn't register taps...
      color:
          children.isEmpty ? const Color(0x00000000) : const Color(0x00000000),
      child: Stack(
        //crossAxisAlignment: CrossAxisAlignment.end,
        children: children,
      ),
    );
  }
}
