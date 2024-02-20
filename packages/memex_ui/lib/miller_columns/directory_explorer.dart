/// A Miller columns view for browsing the file system tree.

import 'dart:io';

import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/miller_columns/miller_columns.dart';

class DirectoryExplorer extends StatelessWidget {
  final void Function(
      RawKeyEvent, MillerColumnsState<String, FileSystemEntity>)? onKey;

  final void Function(File)? onSelect;

  final bool showHidden;

  final IList<String>? initialPath;

  final int? columnCount;

  const DirectoryExplorer({
    Key? key,
    this.onKey,
    this.onSelect,
    this.initialPath,
    this.columnCount,
    this.showHidden = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => MillerColumns<String, FileSystemEntity>(
        rootNode: Directory("/"),
        initialPath: initialPath ?? <String>["home"].lockUnsafe,
        columnCount: columnCount ?? 5,
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
                .where((child) =>
                    showHidden ||
                    !child.key.startsWith(".") ||
                    (initialPath ?? [].lockUnsafe).contains(child.key))
                .toList();
            // Sort by name.
            entries.sort((a, b) => a.key.compareTo(b.key));
            return entries;
          } catch (e) {
            return null;
          }
        },
        rowBuilder: (context, file, isSelected) => [
          MemexIcon(
            file is Directory
                ? CupertinoIcons.folder_fill
                : CupertinoIcons.doc_fill,
          ),
          const SizedBox(width: 8),
          Text(
            file.path.split("/").last,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ).expanded(),
          if (isSelected && file is Directory)
            const MemexIcon(CupertinoIcons.right_chevron),
        ].toRow(),
        onSelect: (file) {
          assert(file is File);
          onSelect?.call(file as File);
        },
      );
}
