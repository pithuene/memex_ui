import 'dart:io';

import 'package:memex_ui/memex_ui.dart';

Future<void> notify(
  String summary, {
  String? body,
  int? durationMs,
}) async {
  await Process.run(
    "notify-send",
    [
      ...durationMs != null ? ["--expire-time=$durationMs"] : [],
      "--app-name=$memexAppName",
      summary,
      ...body != null ? [body] : [],
    ],
  );
}
