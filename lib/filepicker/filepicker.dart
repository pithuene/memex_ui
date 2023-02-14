import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

void openOverlay(
    BuildContext context, Widget Function(BuildContext, OverlayEntry) builder) {
  OverlayState overlayState = Overlay.of(context)!;
  OverlayEntry? overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => ColoredBox(
      color: const Color(0x55000000),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8.0,
          sigmaY: 8.0,
        ),
        child: Center(child: builder(context, overlayEntry!)),
      ),
    ),
  );
  overlayState.insert(overlayEntry);
}

Future<File> openFilepicker(BuildContext context) async {
  var completer = Completer<File>();

  openOverlay(
    context,
    (context, entry) => Filepicker(
      overlayEntry: entry,
      onSelect: (file) {
        completer.complete(file);
      },
    ),
  );

  return completer.future;
}

class Filepicker extends StatefulWidget {
  final OverlayEntry overlayEntry;
  final void Function(File) onSelect;
  Filepicker({
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

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
    setState(() {
      updateColumns();
    });
  }

  void moveLeft() {
    setState(() {
      currentPath = current.parent.path.split("/").sublist(1).lockUnsafe;
      updateColumns();
    });
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

    leftColumn = parentsParent.listSync();
    centerColumn = parent.listSync();
    rightColumn = (current is Directory)
        ? rightColumn = (current as Directory).listSync()
        : [];
  }

  List<Widget> columnWidgets(
      List<FileSystemEntity> entities, String highlightedPath) {
    return entities
        .map(
          (entry) => entry.path == highlightedPath
              ? ColoredBox(
                  color: Colors.lightBlue.withOpacity(0.5),
                  child: Text(entry.path.split("/").last),
                )
              : Text(entry.path.split("/").last),
        )
        .toList();
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
        if (event is KeyDownEvent) {
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
      child: Padding(
        padding: EdgeInsets.all(50),
        child: ColoredBox(
          color: Color(0xFFFFFFFF),
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  children: columnWidgets(
                    leftColumn,
                    current.parent.path,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: columnWidgets(
                    centerColumn,
                    current.path,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: columnWidgets(
                    rightColumn,
                    "",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
