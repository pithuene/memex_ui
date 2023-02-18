import 'dart:io';
import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:memex_ui/editor/block.dart';
import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/cursor.dart';
import 'package:memex_ui/editor/piece_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/memex_ui.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

/// Parse the text content components in pandocs JSON format.
IList<Piece> _parseContent({
  required List content,
  bool appendSentinel = false,
  bool isBold = false,
  bool isItalic = false,
}) {
  List<Piece> pieces = [];
  for (Map jsonPiece in content) {
    switch (jsonPiece["t"]) {
      case "Str":
        {
          pieces.add(
            Piece(
              text: jsonPiece["c"],
              isBold: isBold,
              isItalic: isItalic,
            ),
          );
        }
        break;
      case "Space":
        {
          pieces.add(
            Piece(
              text: " ",
              isBold: isBold,
              isItalic: isItalic,
            ),
          );
        }
        break;
      case "SoftBreak":
        {
          pieces.add(
            Piece(
              text: "\n",
              isBold: isBold,
              isItalic: isItalic,
            ),
          );
        }
        break;
      case "Strong":
        {
          pieces.addAll(
            _parseContent(
              content: jsonPiece["c"],
              isBold: true,
              isItalic: isItalic,
            ),
          );
        }
        break;
      case "Emph":
        {
          pieces.addAll(
            _parseContent(
              content: jsonPiece["c"],
              isBold: isBold,
              isItalic: true,
            ),
          );
        }
        break;
      case "Quoted":
        {
          String quoteType = jsonPiece["c"][0]["t"];
          Piece? quotePiece;
          if (quoteType == "SingleQuote") {
            quotePiece = Piece(
              text: "'",
              isBold: isBold,
              isItalic: isItalic,
            );
          } else if (quoteType == "DoubleQuote") {
            quotePiece = Piece(
              text: "\"",
              isBold: isBold,
              isItalic: isItalic,
            );
          } else {
            print("Unknown quote type $quoteType");
          }

          if (quotePiece != null) pieces.add(quotePiece);
          pieces.addAll(
            _parseContent(content: jsonPiece["c"][1]),
          );
          if (quotePiece != null) pieces.add(quotePiece);
        }
        break;
      case "Link":
        {
          pieces.add(
            LinkPiece(
              children: _parseContent(content: jsonPiece["c"][1]),
              target: jsonPiece["c"][2][0],
            ),
          );
        }
        break;
      default:
        {
          // TODO: Return an error
          print("Failed to parse content piece of type ${jsonPiece["t"]}");
          print(jsonPiece);
        }
        break;
    }
  }
  if (appendSentinel) {
    pieces.add(Piece.sentinel);
  }
  return pieces.lockUnsafe;
}

List<EditorBlock> _parseBulletList(List bulletListEntries) {
  EditorBlock _parseBulletListEntry(List bulletListEntryWithChildren) =>
      BulletpointBlock(
        _parseContent(
          content: bulletListEntryWithChildren[0]["c"],
          appendSentinel: true,
        ),
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
      return [
        SectionBlock(
          _parseContent(
            content: jsonBlock["c"][2],
            appendSentinel: true,
          ),
        )
      ];
    //final level = jsonBlock["c"][0];
    case "Para":
      return [
        ParagraphBlock(
          _parseContent(
            content: jsonBlock["c"],
            appendSentinel: true,
          ),
        )
      ];
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
      piecePath: PiecePath(IListConst([0])),
      offset: 0,
    )),
  );
}

Future<Map> pandocMarkdownToJson(File markdownFile) async {
  ProcessResult result = await Process.run(
    "pandoc",
    [
      "-f",
      "markdown+lists_without_preceding_blankline",
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
