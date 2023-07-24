import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:memex_editor/document.dart';
import 'package:memex_editor/open_documents.dart';
import 'package:memex_ui/memex_ui.dart';

class MemexEditorSidebar extends ReactiveWidget {
  final DocumentStore documentStore;
  final Prop<Document?> currentDocument;
  const MemexEditorSidebar({
    super.key,
    required this.documentStore,
    required this.currentDocument,
  });

  @override
  Widget build(BuildContext context) => ListView(
        children: documentStore.value.map((document) {
          return GestureDetector(
            onTap: () {
              currentDocument.value?.save();
              documentStore.appendToHistory(document);
              currentDocument.value = document;
            },
            child: HoverDetector(
              cursor: SystemMouseCursors.click,
              builder: (context, isHovered, child) => Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(3.0)),
                  color: isHovered
                      ? Colors.black.withOpacity(0.1)
                      : Colors.transparent,
                ),
                padding: const EdgeInsets.all(5),
                child: child,
              ),
              child: Row(
                children: [
                  (document.hasIcon)
                      ? Text(document.icon!)
                      : const MemexIcon(CupertinoIcons.doc),
                  Container(width: 5.0),
                  Expanded(
                    child: Text(
                      document.titleFormated,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
}
