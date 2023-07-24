import 'dart:collection';
import 'dart:io';
import 'package:memex_editor/document.dart';
import 'package:memex_ui/memex_ui.dart';

/// A list of the ids of recently opened notes.
/// Internally stores a cache of open documents,
/// so they don't need to be read from file every time.
class DocumentStore extends ReactiveValue<List<Document>> {
  final int maxHistoryLength = 10;

  Queue<Document> history = Queue();
  Queue<Document> forwardQueue = Queue();

  @override
  List<Document> get value {
    ReactiveListener.currentContextListener?.listenTo(this);
    return history.toList();
  }

  Future<Document?> openNoteFromFile(File file) async {
    Document note;
    final openDocumentsWithSamePath = <Document>{};
    openDocumentsWithSamePath.addAll(
      history.where((doc) => doc.file.path == file.path),
    );
    openDocumentsWithSamePath.addAll(
      forwardQueue.where((doc) => doc.file.path == file.path),
    );
    Document? alreadyOpenDocument = (openDocumentsWithSamePath.isEmpty)
        ? null
        : openDocumentsWithSamePath.first;

    if (alreadyOpenDocument != null) {
      // [Document] is already open.
      note = alreadyOpenDocument;
    } else {
      // Create a new [Document]
      note = Document(file: file);
      if (!await note.open()) {
        return null;
      }
    }

    appendToHistory(note);
    return note;
  }

  void appendToHistory(Document document) {
    if (history.length >= maxHistoryLength) {
      // TODO: You could save the removed doc her. Usually it should already be saved though.
      history.removeFirst();
    }
    history.add(document);
    forwardQueue.clear();
    notifyListeners();
  }

  Document? back() {
    if (history.length <= 1) return null;
    forwardQueue.add(history.removeLast());
    notifyListeners();
    return history.last;
  }

  Document? forward() {
    if (forwardQueue.isEmpty) return null;
    Document nextDocument = forwardQueue.removeLast();
    history.add(nextDocument);
    notifyListeners();
    return nextDocument;
  }
}
