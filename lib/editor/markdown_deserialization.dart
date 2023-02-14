import 'dart:io';
import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:memex_ui/editor/block.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/cursor.dart';
import 'package:memex_ui/memex_ui.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

/// Parse the text content components in pandocs JSON format.
IList<TextSpan> _parseContent(List jsonContent) {
  List<TextSpan> pieces = [];
  for (Map jsonPiece in jsonContent) {
    switch (jsonPiece["t"]) {
      case "Str":
        {
          pieces.add(
            TextSpan(
              text: jsonPiece["c"],
            ),
          );
        }
        break;
      case "Space":
        {
          pieces.add(
            const TextSpan(
              text: " ",
            ),
          );
        }
        break;
      default:
        {
          // TODO: Return an error
          print("Failed to parse content piece of type ${jsonPiece["t"]}");
        }
        break;
    }
  }
  pieces.add(EditorBlock.sentinelPiece);
  return pieces.lockUnsafe;
}

List<EditorBlock> _parseBulletList(List bulletListEntries) {
  EditorBlock _parseBulletListEntry(List bulletListEntryWithChildren) =>
      BulletpointBlock(
        _parseContent(bulletListEntryWithChildren[0]["c"]),
        _parseBlocks(bulletListEntryWithChildren.sublist(1)).toIList(),
      );

  return bulletListEntries
      .map((bulletListEntry) => _parseBulletListEntry(bulletListEntry))
      .toList();
}

List<EditorBlock> _parseBlocks(List jsonBlocks) {
  if (jsonBlocks.isEmpty) return [];
  return jsonBlocks.map((jsonBlock) => _parseBlock(jsonBlock)).toList().reduce(
    (value, elements) {
      value.addAll(elements);
      return value;
    },
  );
}

/// Recursively parse the JSON definition of a block.
List<EditorBlock> _parseBlock(Map jsonBlock) {
  String type = jsonBlock["t"];
  switch (type) {
    case "Header":
      return [SectionBlock(_parseContent(jsonBlock["c"][2]))];
    //final level = jsonBlock["c"][0];
    case "Para":
      return [ParagraphBlock(_parseContent(jsonBlock["c"]))];
    case "BulletList":
      return _parseBulletList(jsonBlock["c"]);
    default:
      {
        // TODO: Return an error
        print("Failed to parse block of type $type");
        print(jsonBlock.toString());
        return [];
      }
  }
}

Future<EditorState> parseMarkdown(File markdownFile) async {
  Map json = await pandocMarkdownToJson(markdownFile);
  List<EditorBlock> blocks = (json["blocks"] as List)
      .map((block) => _parseBlock(block))
      .fold([], (List<EditorBlock> blocks, Iterable<EditorBlock> newBlocks) {
    blocks.addAll(newBlocks);
    return blocks;
  });

  return EditorState(
    blocks: blocks.toIList(),
    selection: const Selection.collapsed(Cursor(
      blockPath: BlockPath(IListConst([0])),
      pieceIndex: 0,
      offset: 0,
    )),
  );
}

Future<Map> pandocMarkdownToJson(File markdownFile) async {
  ProcessResult result = await Process.run(
    "pandoc",
    [
      "-f",
      "markdown",
      "-t",
      "json",
      markdownFile.path,
    ],
  );
  if (result.exitCode != 0) {
    return Future.error("Pandoc error: ${result.stderr.toString()}");
  }
  return jsonDecode(result.stdout.toString());
}
