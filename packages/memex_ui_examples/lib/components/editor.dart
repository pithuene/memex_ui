import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components.dart';

class StoryEditorDefault extends Story {
  StoryEditorDefault({
    super.name = "Default",
  });

  final editorState = EditorState(
    document: markdownToDocument('''
# Hello World

Here is a paragraph

- Bullet
- List
  - Nested
  - [x] And Done
  - [ ] Not Done
- List

1. Numbered
  1. Nested
2. Not nested

---


> Quote
> 
> by someone

'''),
  );

  @override
  Widget build(BuildContext context) => EditorView(
        editorState: editorState,
      );
}

ComponentExample componentEditor() => ComponentExample(
      name: "Editor",
      stories: [
        StoryEditorDefault(),
      ],
    );
