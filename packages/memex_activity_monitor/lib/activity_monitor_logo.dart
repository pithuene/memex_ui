import 'package:flutter/widgets.dart';

class ActivityMonitorLogo extends StatelessWidget {
  final double size;

  const ActivityMonitorLogo({
    Key? key,
    this.size = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      // Image from https://findicons.com/icon/131419/activity_monitor where it is listed as "Freeware Non-commercial"
      "assets/activity_monitor.png",
      width: size,
      height: size,
    );
  }
}
