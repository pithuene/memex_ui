<img align="right" src="./assets/activity_monitor.png"/>

# Activity Monitor

Find out what processes are running on your Linux machine using a MacOS inspired Activity Monitor.
Reads information directly out of the Linux `/proc` directory, which is then displayed using a Flutter UI.

Getting Started
---------------

Using Nix, run `nix-shell` to launch a shell with all the necessary dependencies available.
Next, run `flutter run -d linux` to launch the application.

Submodules
----------

The UI is implemented using the [macos_ui](https://github.com/GroovinChip/macos_ui) package.
A fork of this is included under `packages/macos_ui` because I intend to add some missing widgets to the library.
