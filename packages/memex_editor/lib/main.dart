import 'dart:io';
import 'package:flutter/services.dart';
import 'package:memex_editor/document.dart';
import 'package:memex_editor/document_header.dart';
import 'package:memex_editor/open_documents.dart';
import 'package:memex_editor/sidebar.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/memex_ui.dart';

import 'package:memex_ui/new_editor/editor.dart' as editor;

void main(List<String> args) {
  runApp(const MemexEditorApp());
}

class MemexEditorApp extends StatefulWidget {
  const MemexEditorApp({super.key});

  @override
  State<StatefulWidget> createState() => _MemexEditorAppState();
}

class _MemexEditorAppState extends State<MemexEditorApp> {
  final editorWrapperFocusNode = FocusNode(skipTraversal: false);

  DocumentStore documentStore = DocumentStore();
  Prop<Document?> currentDocument = Prop<Document?>(null);
  Prop<bool> useExperimentalEditor = Prop(true);

  Future<void> openNoteFromId(String id) async {
    ProcessResult result = await Process.run(
      "zkpth",
      [id],
    );
    if (result.exitCode != 0) {
      return Future.error("zkpth could not find id $id");
    }
    File file = File(result.stdout.toString().trim());
    await openNoteFromFile(file);
  }

  Future<void> openNoteFromFile(File file) async {
    // Ensure it is a markdown file.
    assert(file.path.split(".").last == "md");

    // TODO: Save current document?
    Document? note = await documentStore.openNoteFromFile(file);
    if (note == null) return;
    currentDocument.value = note;
  }

  Future<String?> searchNote(BuildContext context) async {
    String? selectedPath = await openSearchPopup<String>(
      context,
      fdInKasten,
      (context, path) => Text(Document.titleFromPath(path)),
    );
    editorWrapperFocusNode.nextFocus();
    return selectedPath;
  }

  Future<void> searchAndOpenNote(BuildContext context) async {
    // Open a file
    //File selectedFile = await openFilepicker(context);
    String? selectedPath = await searchNote(context);
    if (selectedPath == null) return;
    File selectedFile = File(selectedPath);
    await openNoteFromFile(selectedFile);
  }

  Future<void> openJournalEntry({
    DateTime? date,
  }) async {
    ProcessResult result = await Process.run(
      "zkjrnl",
      date == null ? [] : ["${date.year}-${date.month}-${date.day}"],
    );
    if (result.exitCode != 0) {
      return Future.error("zkjrnl failed: ${result.stderr.toString()}");
    }
    File file = File(result.stdout.toString().trim());
    assert(await file.exists());
    await openNoteFromFile(file);
  }

  Future<void> createAndLinkNewNote(BuildContext context, Editor editor) async {
    String? newTitle = await openSearchPopup<String>(
      context,
      (query) async => query == null ? [] : [query],
      (context, title) => Text(title),
    );
    editorWrapperFocusNode.nextFocus();
    if (newTitle == null || newTitle.isEmpty) return;

    ProcessResult result = await Process.run(
      "zttl",
      [newTitle],
    );
    if (result.exitCode != 0) {
      return Future.error("zttl failed");
    }
    File file = File(result.stdout.toString().trim());
    assert(await file.exists());

    editor.appendLink(
      Document.idFromPath(file.path),
      <Piece>[
        Piece(text: Document.titleFromPath(file.path)),
      ].lockUnsafe,
    );
    editor.rebuild();
    //await openNoteFromFile(file);
  }

  /// Search a note and append a link to it.
  Future<void> searchAndLinkToNote(BuildContext context, Editor editor) async {
    String? selectedPath = await searchNote(context);
    editorWrapperFocusNode.nextFocus();
    if (selectedPath == null || selectedPath.isEmpty) return;
    editor.appendLink(
      Document.idFromPath(selectedPath),
      <Piece>[
        Piece(text: Document.titleFromPath(selectedPath)),
      ].lockUnsafe,
    );
    editor.rebuild();
  }

  Future<List<String>> fdInKasten(String? query) async {
    if (query == null) return [];
    ProcessResult result = await Process.run(
      "fd",
      [
        "-e",
        "md",
        "-d",
        "1",
        query,
        "/home/pit/kasten",
      ],
    );
    if (result.exitCode != 0) {
      return Future.error("fd error: ${result.stderr.toString()}");
    }
    List<String> results = result.stdout.toString().split("\n");
    results.removeLast();
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return App(
      appName: "Memex Editor",
      sidebar: Sidebar(
        minWidth: 150,
        topOffset: 16,
        top: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            "Open Notes",
            style: MemexTypography.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        builder: (context, scrollController) => MemexEditorSidebar(
          currentDocument: currentDocument,
          documentStore: documentStore,
        ),
      ),
      toolBar: ToolBar(
        titleWidth: 400,
        title: ReactiveBuilder(
          () => (currentDocument.value == null)
              ? Row(
                  children: [
                    const Text("Memex Editor"),
                    Switch(useExperimentalEditor),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ...(currentDocument.value!.hasIcon)
                        ? [
                            Text(currentDocument.value!.icon!),
                            Container(width: 10),
                          ]
                        : [],
                    Expanded(
                      child: Text(currentDocument.value!.titleFormated),
                    ),
                  ],
                ),
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MacosIconButton(
              icon: const MemexIcon(CupertinoIcons.left_chevron),
              onPressed: () async {
                Document? lastDoc = documentStore.back();
                if (lastDoc != null) {
                  currentDocument.value?.save();
                  currentDocument.value = lastDoc;
                }
              },
            ),
            MacosIconButton(
              icon: const MemexIcon(CupertinoIcons.right_chevron),
              onPressed: () async {
                Document? nextDoc = documentStore.forward();
                if (nextDoc != null) {
                  currentDocument.value?.save();
                  currentDocument.value = nextDoc;
                }
              },
            ),
          ],
        ),
      ),
      builder: (context, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ReactiveBuilder(() => RawKeyboardListener(
                  focusNode: editorWrapperFocusNode,
                  autofocus: true,
                  onKey: (event) {
                    if (event is! RawKeyDownEvent) return;
                    if (!event.isControlPressed) return;

                    if (event.logicalKey == LogicalKeyboardKey.keyO) {
                      searchAndOpenNote(context);
                    } else if (event.logicalKey == LogicalKeyboardKey.keyJ) {
                      openJournalEntry();
                    }

                    if (currentDocument.value == null) return;
                    if (event.logicalKey == LogicalKeyboardKey.keyS) {
                      currentDocument.value!.save();
                    }
                    if (event.logicalKey == LogicalKeyboardKey.keyL) {
                      searchAndLinkToNote(
                          context, currentDocument.value!.editor!);
                    }
                    if (event.logicalKey == LogicalKeyboardKey.keyN) {
                      createAndLinkNewNote(
                          context, currentDocument.value!.editor!);
                    }
                  },
                  child: (useExperimentalEditor.value)
                      ? editor.Editor(
                          document: editor.EditorDocument(
                            children: [
                              //editor.EditorSelection(
                              //children: [
                              editor.EditorText(TextEditingValue(
                                  text:
                                      "Testing something with a lot of content, so I can see whether the lines break properly. Let's see some more content because this was not enough.")),
                              editor.EditorParagraph(
                                children: [
                                  editor.EditorSpanPlain("In Color: "),
                                  editor.EditorSpanBlue(
                                    children: [
                                      editor.EditorSpanPlain("Test"),
                                      editor.EditorSpanBold("Test"),
                                    ].lockUnsafe,
                                  ),
                                ].lockUnsafe,
                                //),
                                //].lockUnsafe,
                                /*selection: editor.Selection.collapsed(
                                  editor.Cursor(editor.NodePath([0, 1]), 1),
                                ),*/
                              ),
                            ].lockUnsafe,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 64),
                          child: (currentDocument.value == null)
                              ? Text(
                                  "Open a document to start editing.",
                                  style: MemexTypography.body.copyWith(
                                    color: MemexColor.text.withOpacity(0.5),
                                  ),
                                )
                              : EditorView(
                                  scrollController: scrollController,
                                  editor: currentDocument.value!.editor!,
                                  linkHandler: (target) async =>
                                      openNoteFromId(target),
                                  header: DocumentHeader(
                                    document: currentDocument,
                                    openJournalDate: (DateTime date) {
                                      openJournalEntry(date: date);
                                    },
                                  ),
                                  footer: Container(height: 200),
                                ),
                        ),
                )),
          ),
        ],
      ),
    );
  }
}
