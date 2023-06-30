import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components.dart';

ComponentExample componentHoverDetector() => ComponentExample(
      name: "HoverDetector",
      stories: [
        Story(
          "Default",
          (BuildContext context) => Center(
            child: HoverDetector(
              builder: (context, hovered, child) => Container(
                color:
                    hovered ? const Color(0xFFFF0000) : const Color(0xFF0000FF),
                child: child,
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Text("Content"),
              ),
            ),
          ),
        ),
      ],
    );
