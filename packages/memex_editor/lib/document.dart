import 'dart:io';
import 'package:intl/intl.dart';

import 'package:memex_ui/editor/editor.dart';
import 'package:memex_ui/editor/editor_state.dart';
import 'package:memex_ui/editor/markdown_deserialization.dart';
import 'package:memex_ui/editor/markdown_serialization.dart';
import 'package:memex_ui/notify/notify.dart';

/// Represents a zettel which is currently open.
class Document {
  /// The [Editor] instance of this document.
  Editor? editor; //  = Editor(EditorState.empty());

  bool get isOpen => editor != null;

  bool get hasIcon => editor?.state.meta.containsKey("icon") ?? false;
  String? get icon => editor?.state.meta["icon"];

  /// The [File] in which this [Document] is saved.
  final File file;

  /// The title of the [Document].
  final String title;

  /// Whether this document is a journal entry.
  bool get isJournalEntry =>
      RegExp(r'^\d\d\d\d\.\d\d\.\d\d$').matchAsPrefix(title) != null;

  DateTime get journalDate {
    assert(isJournalEntry);
    final titleSplit = title.split(".");
    return DateTime(
      int.parse(titleSplit[0]),
      int.parse(titleSplit[1]),
      int.parse(titleSplit[2]),
    );
  }

  String get titleFormated {
    bool datesMatch(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    if (isJournalEntry) {
      DateTime noteDate = journalDate;
      final now = DateTime.now();
      if (datesMatch(now, noteDate)) {
        return "Today";
      }
      if (datesMatch(now.add(const Duration(days: 1)), noteDate)) {
        return "Tomorrow";
      }
      if (datesMatch(now.subtract(const Duration(days: 1)), noteDate)) {
        return "Yesterday";
      }
      return DateFormat("EEEE d. MMMM y").format(noteDate);
    }
    return title;
  }

  /// The id of the [Document], the part in parentheses
  /// just before the file extension.
  final String id;

  Document({
    required this.file,
  })  : title = Document.titleFromPath(file.path),
        id = Document.idFromPath(file.path),
        editor = null;

  static String titleFromPath(String filePath) {
    String fileName = filePath.split("/").last;
    int spaceAfterNameIndex = fileName.lastIndexOf("(") - 1;
    return fileName.substring(0, spaceAfterNameIndex);
  }

  static String idFromPath(String filePath) {
    String fileName = filePath.split("/").last;
    int spaceAfterNameIndex = fileName.lastIndexOf("(") + 1;
    String idAndExtension = fileName.substring(spaceAfterNameIndex);
    return idAndExtension.substring(0, idAndExtension.indexOf(")"));
  }

  /// If the document is not yet opened, read it from file.
  /// Returns whether the note is now open.
  Future<bool> open() async {
    if (isOpen) return true;
    EditorState? state = await parseMarkdown(file);
    if (state == null) {
      notify("Deserialization error in ${Document.titleFromPath(file.path)}");
      return false;
    }
    editor = Editor(state);
    return true;
  }

  /// Serialize the document and save it back to file.
  Future<void> save() async {
    assert(isOpen);
    String markdown = await serializeEditorState(editor!.state);
    await file.writeAsString(markdown);
    notify("Saved", body: title, durationMs: 500);
  }
}
