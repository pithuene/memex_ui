import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/miller_columns/directory_explorer.dart';

void main(List<String> arguments) {
  String stringPath =
      arguments.isNotEmpty ? arguments.first : Platform.environment['PWD']!;
  if (stringPath.startsWith("~")) {
    stringPath = stringPath.replaceFirst("~", Platform.environment['HOME']!);
  }
  stringPath = path.normalize(stringPath);
  IList<String> pathComponents = path.split(stringPath).lock;
  if (pathComponents.first == "/") {
    pathComponents = pathComponents.sublist(1);
  }

  runApp(MemexFilepicker(pathComponents));
}

class MemexFilepicker extends StatelessWidget {
  final IList<String> initialPath;
  const MemexFilepicker(this.initialPath, {super.key});

  @override
  Widget build(BuildContext context) => App(
        appName: "Filepicker",
        builder: (context, scrollController) => DirectoryExplorer(
          initialPath: initialPath,
          columnCount: 3,
          onSelect: (file) {
            stdout.writeln(file.path);
            exit(0);
          },
        ),
      );
}
