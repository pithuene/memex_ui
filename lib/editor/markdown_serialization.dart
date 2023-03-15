import 'dart:io';
import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:memex_ui/editor/blocks/bulletpoint_block.dart';
import 'package:memex_ui/editor/blocks/code_block.dart';
import 'package:memex_ui/editor/blocks/editor_block.dart';
import 'package:memex_ui/editor/blocks/math_block.dart';
import 'package:memex_ui/editor/blocks/paragraph_block.dart';
import 'package:memex_ui/editor/blocks/quote_block.dart';
import 'package:memex_ui/editor/blocks/heading_block.dart';
import 'package:memex_ui/editor/pieces.dart';
import 'package:memex_ui/memex_ui.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

/// Serialize a list of pieces to their plaintext content.
String piecesToPlaintext(IList<Piece> pieces) {
  return TextSpan(
    children: pieces
        .map((child) => child.toSpan(Editor(EditorState.empty()), true))
        .toList(),
  ).toPlainText();
}

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
      "markdown"
          "-simple_tables"
          "-grid_tables"
          "-multiline_tables"
          "-smart",
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

Map _serializePiece(Piece piece) {
  switch (piece.runtimeType) {
    case Piece:
      return {
        "t": "Str",
        "c": piece.text,
      };
    case LinkPiece:
      return {
        "t": "Link",
        "c": [
          ["", [], []],
          _serializeTextContent((piece as LinkPiece).children),
          [piece.target, ""],
        ],
      };
    case InlineMathPiece:
      return {
        "t": "Math",
        "c": [
          {"t": "InlineMath"},
          piecesToPlaintext((piece as InlineMathPiece).children),
        ],
      };
    case FootnotePiece:
      return {
        "t": "Note",
        "c": [
          {
            "t": "Para",
            "c": _serializeTextContent((piece as FootnotePiece).children),
          },
        ],
      };
    default:
      {
        print("Failed to serialize piece of type ${piece.runtimeType}!");
        return {
          "t": "Str",
          "c": piece.text,
        };
      }
  }
}

List _serializeTextContent(IList<Piece> pieces) {
  List recursiveSerializeTextContent(
    IList<Piece> pieces,
    IMap<String, bool> state,
  ) {
    List serializedPieces = [];
    IList<Piece> remainingPieces = pieces;
    while (remainingPieces.isNotEmpty) {
      final nextPiece = remainingPieces.first;
      if (nextPiece.isBold && !state["isBold"]!) {
        // Starting bold
        int firstNonBold = remainingPieces.indexWhere((piece) => !piece.isBold);
        if (firstNonBold < 0) {
          firstNonBold = remainingPieces.length;
        }
        serializedPieces.add({
          "t": "Strong",
          "c": recursiveSerializeTextContent(
            remainingPieces.sublist(0, firstNonBold),
            state.add("isBold", true),
          ),
        });
        remainingPieces = remainingPieces.removeRange(0, firstNonBold);
      } else if (nextPiece.isItalic && !state["isItalic"]!) {
        // Starting italic
        int firstNonItalic =
            remainingPieces.indexWhere((piece) => !piece.isItalic);
        if (firstNonItalic < 0) {
          firstNonItalic = remainingPieces.length;
        }
        serializedPieces.add({
          "t": "Emph",
          "c": recursiveSerializeTextContent(
            remainingPieces.sublist(0, firstNonItalic),
            state.add("isItalic", true),
          ),
        });
        remainingPieces = remainingPieces.removeRange(0, firstNonItalic);
      } else if (nextPiece.isMonospace && !state["isMonospace"]!) {
        // Starting monospace
        int firstNonMonospace =
            remainingPieces.indexWhere((piece) => !piece.isMonospace);
        if (firstNonMonospace < 0) {
          firstNonMonospace = remainingPieces.length;
        }
        serializedPieces.add({
          "t": "Code",
          "c": [
            ["", [], []],
            piecesToPlaintext(remainingPieces.sublist(0, firstNonMonospace)),
          ],
        });
        remainingPieces = remainingPieces.removeRange(0, firstNonMonospace);
      } else {
        serializedPieces.add(_serializePiece(nextPiece));
        remainingPieces = remainingPieces.removeAt(0);
      }
    }
    return serializedPieces;
  }

  return recursiveSerializeTextContent(
    (pieces.last == Piece.sentinel) ? pieces.removeLast() : pieces,
    {
      "isBold": false,
      "isItalic": false,
      "isMonospace": false,
    }.toIMap(),
  );
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
    case HeadingBlock:
      return {
        "t": "Header",
        "c": [
          (block as HeadingBlock).level,
          ["", [], []],
          _serializeTextContent(block.pieces)
        ]
      };
    case MathBlock:
      return {
        "t": "Para",
        "c": [
          {
            "t": "Math",
            "c": [
              {"t": "DisplayMath"},
              piecesToPlaintext(block.pieces.removeLast())
            ]
          }
        ]
      };
    case CodeBlock:
      return {
        "t": "CodeBlock",
        "c": [
          [
            "",
            [(block as CodeBlock).language],
            []
          ],
          piecesToPlaintext(block.pieces.removeLast())
        ]
      };
    case QuoteBlock:
      return {
        "t": "BlockQuote",
        "c": [
          {
            "t": "Para",
            "c": _serializeTextContent(block.pieces),
          }
        ]
      };
    default:
      {
        print("Failed to serialize block of type ${block.runtimeType}");
        return;
      }
  }
}
