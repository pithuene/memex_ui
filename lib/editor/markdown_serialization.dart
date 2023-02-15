import 'dart:io';
import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:memex_ui/editor/block.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/memex_ui.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

Future<String> serializeEditorState(EditorState state) async {
  Process pandocProcess = await Process.start(
    "pandoc",
    [
      "--standalone",
      "--wrap=preserve",
      "--markdown-headings=setext",
      "--tab-stop=2",
      "-f",
      "json",
      "-t",
      "markdown-simple_tables-grid_tables-multiline_tables-smart",
    ],
  );

  StringBuffer result = StringBuffer();
  pandocProcess.stdout
      .transform(utf8.decoder)
      .forEach((chunk) => result.write(chunk));

  StringBuffer error = StringBuffer();
  pandocProcess.stderr
      .transform(utf8.decoder)
      .forEach((chunk) => error.write(chunk));

  pandocProcess.stdin.write(jsonEncode(serializeEditorStateToJSON(state)));
  await pandocProcess.stdin.flush();
  await pandocProcess.stdin.close();
  int exitCode = await pandocProcess.exitCode;

  if (exitCode != 0) {
    print(jsonEncode(serializeEditorStateToJSON(state)));
    return Future.error("Pandoc JSON to markdown error: ${error.toString()}");
  }
  return result.toString();
}

Map serializeEditorStateToJSON(EditorState state) {
  var jsonDocument = {
    "pandoc-api-version": [1, 22, 2, 1],
    "meta": {},
    "blocks": _serializeEditorBlocks(state.blocks).toList(),
  };
  return jsonDocument;
}

Map _serializePiece(InlineSpan piece) {
  switch (piece.runtimeType) {
    case TextSpan:
      return {
        "t": "Str",
        "c": (piece as TextSpan).text,
      };
    case LinkSpan:
      return {
        "t": "Link",
        "c": [
          ["", [], []],
          [
            {"t": "Str", "c": (piece as LinkSpan).text!},
          ],
          [piece.target, ""],
        ],
      };
    default:
      {
        print("Failed to serialize piece of type ${piece.runtimeType}!");
        return {
          "t": "Str",
          "c": piece.toPlainText(),
        };
      }
  }
}

List _serializeTextContent(IList<TextSpan> pieces) {
  return pieces.removeLast().map((piece) => _serializePiece(piece)).toList();
}

/// Find the index the last block in a streak of blocks of type [blockType].
int findListEnd(
  List<EditorBlock> blocks,
  Type blockType,
  int startIndex,
) {
  for (int i = startIndex + 1; i < blocks.length; i++) {
    if (blocks[i].runtimeType != blockType) return i - 1;
  }
  return blocks.length - 1;
}

Iterable _serializeEditorBlocks(IList<EditorBlock> blocks) {
  List result = [];
  for (int i = 0; i < blocks.length; i++) {
    final EditorBlock block = blocks[i];
    if (block.runtimeType == BulletpointBlock) {
      int listEnd = findListEnd(blocks.unlockView, BulletpointBlock, i);
      result.add(_serializeBulletpointBlocks(blocks.sublist(i, listEnd + 1)));
      i = listEnd;
    } else {
      result.add(_serializeEditorBlock(blocks[i]));
    }
  }
  return result;
}

/// Pandoc merges multiple bulletlist blocks into one
/// with multiple "Plain" entries, this handles that.
dynamic _serializeBulletpointBlocks(Iterable<EditorBlock> blocks) {
  List _serializeBulletpointBlock(BulletpointBlock block) {
    return [
      {
        "t": "Plain",
        "c": _serializeTextContent(block.pieces),
      },
      ..._serializeEditorBlocks(block.children),
    ];
  }

  return {
    "t": "BulletList",
    "c": blocks
        .map(
          (block) => _serializeBulletpointBlock(block as BulletpointBlock),
        )
        .toList(),
  };
}

dynamic _serializeEditorBlock(EditorBlock block) {
  switch (block.runtimeType) {
    case ParagraphBlock:
      return {
        "t": "Para",
        "c": _serializeTextContent(block.pieces),
      };
    case SectionBlock:
      return {
        "t": "Header",
        "c": [
          1,
          ["", [], []],
          _serializeTextContent(block.pieces)
        ]
      };
    default:
      {
        print("Failed to serialize block of type ${block.runtimeType}");
        return;
      }
  }
}
