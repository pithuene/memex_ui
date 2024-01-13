import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/miller_columns/directory_explorer.dart';
import 'package:memex_ui/overlay.dart';

Future<File?> openFilepicker(BuildContext context) async {
  var completer = Completer<File?>();

  openOverlay(
    context,
    (context, entry) => DirectoryExplorer(
      onKey: (key, state) {
        if (key.logicalKey == LogicalKeyboardKey.escape) {
          completer.complete(null);
          entry.remove();
        }
      },
      onSelect: (file) {
        completer.complete(file);
        entry.remove();
      },
    )
        .decorated(
          color: const Color(0xFFFFFFFF),
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          border: Border.all(color: Colors.black.withOpacity(0.6)),
        )
        .padding(all: 80),
  );

  return completer.future;
}

class Filepicker extends StatefulWidget {
  final OverlayEntry overlayEntry;
  final void Function(File) onSelect;
  const Filepicker({
    super.key,
    required this.overlayEntry,
    required this.onSelect,
  });

  @override
  State<StatefulWidget> createState() => _FilepickerState();
}

class _FilepickerState extends State<Filepicker> {
  FocusNode focusNode = FocusNode();
  IList<String> currentPath =
      File("/home/pit/Code").absolute.path.split("/").sublist(1).lockUnsafe;

  late FileSystemEntity current;

  List<FileSystemEntity> leftColumn = [];
  List<FileSystemEntity> centerColumn = [];
  List<FileSystemEntity> rightColumn = [];

  GlobalKey centerFocusedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
    setState(() {
      updateColumns();
    });
  }

  void moveLeft() {
    if (currentPath.length > 1) {
      setState(() {
        currentPath = current.parent.path.split("/").sublist(1).lockUnsafe;
        updateColumns();
      });
    }
  }

  void moveRight() {
    if (current is Directory) {
      setState(() {
        currentPath = (current as Directory)
            .listSync()
            .first
            .path
            .split("/")
            .sublist(1)
            .lockUnsafe;
        updateColumns();
      });
    } else {
      close();
      widget.onSelect(current as File);
    }
  }

  void moveDown() {
    List<FileSystemEntity> currentParents = current.parent.listSync();
    int currentIndex = currentParents.indexWhere(
      (element) => element.path == current.path,
    );
    if (currentIndex + 1 < currentParents.length) {
      setState(() {
        currentPath = currentParents[currentIndex + 1]
            .path
            .split("/")
            .sublist(1)
            .lockUnsafe;
        updateColumns();
      });
    }
  }

  void moveUp() {
    List<FileSystemEntity> currentParents = current.parent.listSync();
    int currentIndex = currentParents.indexWhere(
      (element) => element.path == current.path,
    );
    if (currentIndex > 0) {
      setState(() {
        currentPath = currentParents[currentIndex - 1]
            .path
            .split("/")
            .sublist(1)
            .lockUnsafe;
        updateColumns();
      });
    }
  }

  void updateColumns() {
    current = Directory("/${currentPath.join("/")}");
    if (!current.existsSync()) {
      current = File("/${currentPath.join("/")}");
      assert(current.existsSync());
    }
    Directory parent = current.parent;
    Directory parentsParent = parent.parent;

    leftColumn =
        (parent.path == parentsParent.path) ? [] : parentsParent.listSync();
    centerColumn = parent.listSync();
    rightColumn = (current is Directory)
        ? rightColumn = (current as Directory).listSync()
        : [];
  }

  List<Widget> columnWidgets(
    BuildContext context,
    Key? selectedKey,
    List<FileSystemEntity> entities,
    String highlightedPath,
  ) {
    return entities.map(
      (entry) {
        return entry.path == highlightedPath
            ? ColoredBox(
                key: selectedKey,
                color: Colors.lightBlue.withOpacity(0.5),
                child: Text(entry.path.split("/").last),
              )
            : Text(entry.path.split("/").last);
      },
    ).toList();
  }

  void close() {
    widget.overlayEntry.remove();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      focusNode: focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            close();
          } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
            moveLeft();
          } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
            moveRight();
          } else if (event.logicalKey == LogicalKeyboardKey.keyJ) {
            moveDown();
          } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
            moveUp();
          } else {
            print(event);
          }
        }
      },
      child: Row(
        children: [
          ListView(
            children: columnWidgets(
              context,
              null,
              leftColumn,
              current.parent.path,
            ),
          ).expanded(),
          ListView(
            children: columnWidgets(
              context,
              centerFocusedKey,
              centerColumn,
              current.path,
            ),
          ).expanded(),
          ListView(
            children: columnWidgets(
              context,
              null,
              rightColumn,
              "",
            ),
          ).expanded(),
        ],
      ).backgroundColor(MemexColor.white).padding(all: 50),
    );
  }
}
