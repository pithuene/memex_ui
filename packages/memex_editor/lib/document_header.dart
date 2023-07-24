import 'package:emoji_dialog_picker/emoji_dialog_picker.dart';
import 'package:flutter/material.dart';
import 'package:memex_editor/document.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/overlay.dart';

class DocumentHeader extends ReactiveWidget {
  final Prop<Document?> document;
  final Function(DateTime) openJournalDate;

  const DocumentHeader({
    super.key,
    required this.document,
    required this.openJournalDate,
  });

  @override
  Widget build(BuildContext context) => HoverDetector(
        builder: (context, showControls, _) => Padding(
          padding: const EdgeInsets.only(top: 80, bottom: 15),
          child: Column(children: [
            Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      document.value!.titleFormated,
                      style: MemexTypography.heading1,
                    ),
                  ),
                  Container(width: 10),
                  GestureDetector(
                    child: HoverDetector(
                      builder: (
                        context,
                        isHovered,
                        child,
                      ) =>
                          Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(5),
                          ),
                          color: isHovered
                              ? Colors.black.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: child,
                      ),
                      child: document.value!.hasIcon
                          ? Text(
                              document.value!.icon!,
                              style: const TextStyle(
                                fontFamily: "Noto Color Emoji",
                                fontSize: MemexTypography.baseFontSize * 4,
                              ),
                            )
                          : Text(
                              "Add Icon",
                              style: TextStyle(
                                color: showControls
                                    ? MemexColor.text
                                    : Colors.transparent,
                              ),
                            ),
                    ),
                    onTap: () {
                      openOverlay(
                        context,
                        (BuildContext context, OverlayEntry entry) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          ),
                          child: EmojiPickerView(
                            onEmojiSelected: (String emoji) {
                              entry.remove();
                              document.value!.editor?.setIcon(emoji);
                              document.notifyListeners();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ]),
            ...(!document.value!.isJournalEntry)
                ? []
                : [
                    Container(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PushButton(
                          buttonSize: ButtonSize.small,
                          onPressed: () {
                            var prevDay = document.value!.journalDate
                                .subtract(const Duration(days: 1));
                            openJournalDate(prevDay);
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const MacosIcon(
                                CupertinoIcons.left_chevron,
                                size: 18,
                                color: Color(0xFFFFFFFF),
                              ),
                              Container(width: 3),
                              const Text("Previous Day"),
                            ],
                          ),
                        ),
                        PushButton(
                          buttonSize: ButtonSize.small,
                          onPressed: () {
                            var prevDay = document.value!.journalDate
                                .add(const Duration(days: 1));
                            openJournalDate(prevDay);
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("Following Day"),
                              Container(width: 3),
                              const MacosIcon(
                                CupertinoIcons.right_chevron,
                                size: 18,
                                color: Color(0xFFFFFFFF),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
          ]),
        ),
      );
}
