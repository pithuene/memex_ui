import 'package:flutter/services.dart';
import 'package:memex_ui/memex_ui.dart';

class KeyLabel extends StatelessWidget {
  final Shortcut? shortcut;

  /// The first n keys are highlighted.
  final int highlightCount;

  const KeyLabel(
    this.shortcut, {
    super.key,
    this.highlightCount = 0,
  });

  static final textStyle = MemexTypography.body.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: MemexColor.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: MemexColor.grid),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        height: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: shortcut
                  ?.mapIndexedAndLast(
                    (index, item, isLast) => Expanded(
                      child: Text(
                        item.keyLabel,
                        overflow: TextOverflow.clip,
                        style: textStyle.copyWith(
                          color: index < highlightCount
                              ? MemexColor.text
                              : MemexColor.text.withOpacity(0.5),
                        ),
                      ),
                    ),
                  )
                  .toList() ??
              [Text("", style: textStyle)],
        ),
      );
}
