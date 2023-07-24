# Memex Bar

A Wayland bar using Flutter.
Uses [Gtk Layer Shell](https://wmww.github.io/gtk-layer-shell/) to setup a bar and overlay into which Flutter widgets are then rendered.
Allows drawing overlay elements on top of the window content.
If there is overlay content, mouse input over the window area is captured and handled by Flutter.
If there is no overlay content, mouse input in the window area is ignored.
This change of input regions is implemented using a `MethodChannel`.
