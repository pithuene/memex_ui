import 'package:memex_ui/memex_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;

class Popover extends StatelessWidget {
  final Widget child;

  const Popover(this.child, {super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Container(
          //margin: const EdgeInsets.only(top: 0),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            //color: material.Colors.white.withOpacity(0.95),
            color: const Color(0xFFEEEEEE),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(
              color: const Color(0x30000000),
              strokeAlign: BorderSide.strokeAlignOutside,
              width: 0.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: material.Colors.black26,
                blurRadius: 2,
                blurStyle: BlurStyle.normal,
              ),
              BoxShadow(
                color: material.Colors.black26,
                offset: Offset(0, 5),
                blurRadius: 16,
                blurStyle: BlurStyle.normal,
              )
            ],
          ),
          child: child,
        ),
      );
}
