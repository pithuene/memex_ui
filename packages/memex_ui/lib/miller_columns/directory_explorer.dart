/// A Miller columns view for browsing the file system tree.

import 'dart:io';

import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/miller_columns/miller_columns.dart';

class DirectoryExporer extends StatelessWidget {
  final void Function(
      RawKeyEvent, MillerColumnsState<String, FileSystemEntity>)? onKey;

  final void Function(File)? onSelect;

  final bool showHidden;

  const DirectoryExporer({
    Key? key,
    this.onKey,
    this.onSelect,
    this.showHidden = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => MillerColumns<String, FileSystemEntity>(
        rootNode: Directory("/"),
        initialPath: <String>["home", "pit"].lockUnsafe,
        onKey: onKey,
        getChildren: (FileSystemEntity parent) async {
          if (!await FileSystemEntity.isDirectory(parent.path)) {
            return null;
          }
          Directory dir = Directory(parent.path);
          try {
            var entries = dir
                .listSync()
                .map(
                  (child) => NodeAndKey(
                    child,
                    child.path.split("/").last,
                  ),
                )
                .where((child) => showHidden || !child.key.startsWith("."))
                .toList();
            // Sort by name.
            entries.sort((a, b) => a.key.compareTo(b.key));
            return entries;
          } catch (e) {
            return null;
          }
        },
        rowBuilder: (context, file) => Text.rich(
          TextSpan(children: [
            WidgetSpan(
                child: MemexIcon(file is Directory
                    ? CupertinoIcons.folder_fill
                    : CupertinoIcons.doc_fill),
                alignment: PlaceholderAlignment.middle),
            const TextSpan(text: " "),
            TextSpan(text: file.path.split("/").last),
          ]),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        onSelect: (file) {
          assert(file is File);
          onSelect?.call(file as File);
        },
      );
}
