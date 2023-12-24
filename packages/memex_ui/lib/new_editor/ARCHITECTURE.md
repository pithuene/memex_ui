# Editor Nodes

- Editor nodes should be able to access their ancestors
  - If EditorNode is a Widget, this can be implemented using the BuildContext mechanism
  - Otherwise implement this yourself
- Every node must have access to its EditorContext containing things like its path in the tree.
