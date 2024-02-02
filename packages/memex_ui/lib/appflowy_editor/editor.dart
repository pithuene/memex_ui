export 'package:appflowy_editor/src/editor_state.dart';
export 'package:appflowy_editor/src/plugins/markdown/document_markdown.dart';

import 'package:flutter/cupertino.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension _NodeIsList on Node? {
  bool get isList => [
        TodoListBlockKeys.type,
        BulletedListBlockKeys.type,
        NumberedListBlockKeys.type
      ].contains(this?.type);
}

extension _NodeAdjacentShown on Node {
  Node? get lastChild {
    var node = this;
    while (node.children.isNotEmpty) {
      node = node.children.last;
    }
    return node;
  }

  /// The next shown node.
  /// If there is no immediate next note, this is the first child node.
  /// If there are no children, it is the next node of the parent.
  /// Recurses up until the top level if necessary.
  Node? get nextShown => children.firstOrNull ?? next ?? parent?.nextShown;

  /// The previous shown node.
  /// This can be the last child of the previous node (recursively).
  /// If the previous node has no children, it is the previous node.
  /// If there is no previous node, it is the parent node.
  Node? get previousShown => previous?.lastChild ?? previous ?? parent;
}

class EditorView extends ReactiveWidget {
  final EditorState editorState;

  const EditorView({
    super.key,
    required this.editorState,
  });

  EditorStyle customizeEditorStyle() {
    return EditorStyle(
      dragHandleColor: MemexColor.text,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      cursorColor: MemexColor.text,
      selectionColor: MemexColor.textSelection,
      textStyleConfiguration: TextStyleConfiguration(
        text: MemexTypography.body,
        bold: MemexTypography.body.copyWith(fontWeight: FontWeight.bold),
        href: MemexTypography.body.copyWith(
          color: CupertinoColors.link,
          decoration: TextDecoration.underline,
        ),
        code: MemexTypography.code,
      ),
      textSpanDecorator: defaultTextSpanDecoratorForAttribute,
    );
  }

  List<CharacterShortcutEvent> customCharacterShortcutEvents() {
    return [
      //...standardCharacterShortcutEvents,
      customSlashCommand(
        standardSelectionMenuItems,
        style: const SelectionMenuStyle(
          selectionMenuBackgroundColor: MemexColor.white,
          selectionMenuItemTextColor: MemexColor.text,
          selectionMenuItemIconColor: MemexColor.text,
          selectionMenuItemSelectedColor: MemexColor.selection,
          selectionMenuItemSelectedTextColor: MemexColor.white,
          selectionMenuItemSelectedIconColor: MemexColor.white,
        ),
      ),
    ];
  }

  Map<String, BlockComponentBuilder> customBuilder() {
    final configuration = BlockComponentConfiguration(
      textStyle: (node) => MemexTypography.body,
    );

    final listConfiguration = configuration.copyWith(
      padding: (node) => EdgeInsets.only(
        left: 12,
        top: node.previousShown.isList ? 0 : 12,
        bottom: node.nextShown.isList ? 0 : 12,
      ),
    );

    // customize heading block style
    return {
      ...standardBlockComponentBuilderMap,
      // heading block
      HeadingBlockKeys.type: HeadingBlockComponentBuilder(
        configuration: configuration,
      ),
      // todo-list block
      TodoListBlockKeys.type: TodoListBlockComponentBuilder(
        configuration: listConfiguration,
        iconBuilder: (context, node) {
          final checked = node.attributes[TodoListBlockKeys.checked] as bool;
          return MemexIcon(
            checked
                ? CupertinoIcons.checkmark_square_fill
                : CupertinoIcons.square,
            color: CupertinoColors.systemBlue,
            size: 20,
          ).center().padding(right: 4).constrained(minWidth: 26, minHeight: 22);
        },
      ),
      BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
        configuration: listConfiguration,
        iconBuilder: (context, node) =>
            const MemexIcon(CupertinoIcons.circle_fill, size: 8)
                .center()
                .padding(right: 4)
                .constrained(minWidth: 26, minHeight: 22),
      ),
      NumberedListBlockKeys.type: NumberedListBlockComponentBuilder(
        configuration: listConfiguration,
      ),
      QuoteBlockKeys.type: QuoteBlockComponentBuilder(
        configuration: configuration,
        iconBuilder: (context, node) {
          return const EditorSvg(
            width: 20,
            height: 20,
            padding: EdgeInsets.only(right: 5.0),
            name: 'quote',
            color: CupertinoColors.systemBlue,
          );
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) => AppFlowyEditor(
        editorState: editorState,
        editorStyle: customizeEditorStyle(),
        blockComponentBuilders: customBuilder(),
        characterShortcutEvents: customCharacterShortcutEvents(),
      );
}
