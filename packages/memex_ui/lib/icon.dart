export 'package:macos_ui/src/icon/macos_icon.dart';
import 'package:memex_ui/memex_ui.dart';

class MemexIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const MemexIcon(
    this.icon, {
    super.key,
    this.size = MemexTypography.baseFontSize,
    this.color = MemexColor.text,
  });

  @override
  Widget build(BuildContext context) => MacosIcon(
        icon,
        size: size,
        color: color,
      );
}
