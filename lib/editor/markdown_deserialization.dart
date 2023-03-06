import 'dart:io';
import 'dart:convert';

import 'package:memex_ui/editor/block_path.dart';
import 'package:memex_ui/editor/blocks/bulletpoint_block.dart';
import 'package:memex_ui/editor/blocks/code_block.dart';
import 'package:memex_ui/editor/blocks/editor_block.dart';
import 'package:memex_ui/editor/blocks/math_block.dart';
import 'package:memex_ui/editor/blocks/paragraph_block.dart';
import 'package:memex_ui/editor/blocks/section_block.dart';
import 'package:memex_ui/editor/cursor.dart';
import 'package:memex_ui/editor/piece_path.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/editor/selection.dart';
import 'package:memex_ui/memex_ui.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

/// Parse the text content components in pandocs JSON format.
IList<Piece> _parseContent({
  required List content,
  bool appendSentinel = false,
  bool isBold = false,
  bool isItalic = false,
  bool isMonospace = false,
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
              isMonospace: isMonospace,
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
              isMonospace: isMonospace,
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
              isMonospace: isMonospace,
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
              isMonospace: isMonospace,
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
              isMonospace: isMonospace,
            ),
          );
        }
        break;
      case "Code":
        {
          pieces.add(
            Piece(
              text: jsonPiece["c"][1],
              isBold: isBold,
              isItalic: isItalic,
              isMonospace: true,
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
              isMonospace: isMonospace,
            );
          } else if (quoteType == "DoubleQuote") {
            quotePiece = Piece(
              text: "\"",
              isBold: isBold,
              isItalic: isItalic,
              isMonospace: isMonospace,
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
      case "Math":
        {
          pieces.add(
            InlineMathPiece(
              children: <Piece>[Piece(text: jsonPiece["c"][1])].lockUnsafe,
            ),
          );
        }
        break;
      case "Note":
        {
          assert(jsonPiece["c"][0]["t"] == "Para");
          pieces.add(
            FootnotePiece(
              children: _parseContent(content: jsonPiece["c"][0]["c"]),
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
      if (jsonBlock["c"][0]["t"] == "Math" &&
          jsonBlock["c"][0]["c"][0]["t"] == "DisplayMath") {
        return [
          MathBlock([
            Piece(
              text: jsonBlock["c"][0]["c"][1],
            ),
            Piece.sentinel,
          ].lockUnsafe)
        ];
      }

      return [
        ParagraphBlock(
          _parseContent(
            content: jsonBlock["c"],
            appendSentinel: true,
          ),
        )
      ];
    case "CodeBlock":
      return [
        CodeBlock(
          [
            Piece(text: jsonBlock["c"][1]),
            Piece.sentinel,
          ].lockUnsafe,
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
      "markdown"
          "+lists_without_preceding_blankline",
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
