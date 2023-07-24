import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:xdg_directories/xdg_directories.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';

class DesktopEntries {
  List<Directory> applicationDirectories = [];
  List<DesktopEntry> desktopEntries = [];

  List<Directory> pixmapDirectories = [];
  List<File> iconImageFiles = [];

  List<Directory> iconDirectories = [];

  DesktopEntries() {
    _initializeApplicationDirectories();
    _initializeDesktopEntries();

    _initializePixmapDirectories();
    _initializeIconDirectories();

    _initializeIconImages();
  }

  void _initializeApplicationDirectories() {
    Iterable<String> applicationDirPaths =
        dataDirs.map((dir) => '${dir.path}/applications');
    for (String path in applicationDirPaths) {
      Directory dir = Directory(path);
      if (dir.existsSync()) {
        applicationDirectories.add(dir);
      }
    }
  }

  void _initializeDesktopEntries() {
    for (Directory dir in applicationDirectories) {
      for (FileSystemEntity desktopFile in dir.listSync()) {
        desktopEntries
            .add(DesktopEntry.parse((desktopFile as File).readAsStringSync()));
      }
    }
  }

  void _initializePixmapDirectories() {
    Iterable<String> pixmapDirPaths =
        dataDirs.map((dir) => '${dir.path}/pixmaps');
    for (String path in pixmapDirPaths) {
      Directory dir = Directory(path);
      if (dir.existsSync()) {
        pixmapDirectories.add(dir);
      }
    }
  }

  void _initializeIconDirectories() {
    Iterable<String> iconDirPaths =
        dataDirs.map((dir) => '${dir.path}/icons/hicolor/32x32/apps');
    for (String path in iconDirPaths) {
      Directory dir = Directory(path);
      if (dir.existsSync()) {
        iconDirectories.add(dir);
      }
    }
  }

  // Collect all icon images from pixmap and icon directories
  void _initializeIconImages() {
    for (Directory dir in pixmapDirectories) {
      for (FileSystemEntity pixmapFile in dir.listSync()) {
        iconImageFiles.add(pixmapFile as File);
      }
    }
    for (Directory dir in iconDirectories) {
      for (FileSystemEntity iconFile in dir.listSync()) {
        iconImageFiles.add(iconFile as File);
      }
    }
  }

  // Create a map from executable names to icon images
  Map<String, Image> createIconMap() {
    Map<String, Image> iconMap = {};

    for (DesktopEntry de in desktopEntries) {
      String? exec = de.entries[DesktopEntryKey.exec.string]?.value;
      String? name = de.entries[DesktopEntryKey.name.string]?.value;
      String? icon = de.entries[DesktopEntryKey.icon.string]?.value;
      if (icon != null) {
        Iterable<File> pixmapFilesForEntry = iconImageFiles
            .where((pixmapFile) =>
                pixmapFile.path.split("/").last.split(".")[0] == icon)
            .where((pixmapFile) => pixmapFile.path.split(".").last != "xpm");
        if (pixmapFilesForEntry.isNotEmpty) {
          File pixmapFileForEntry = pixmapFilesForEntry.first;
          Image iconImage = Image.file(
            pixmapFileForEntry,
            width: 24,
            height: 24,
          );

          iconMap[icon] = iconImage;
          if (exec != null) iconMap[exec] = iconImage;
          if (name != null) {
            iconMap[name] = iconImage;
            iconMap[name.toLowerCase()] = iconImage;
          }
        }
      }
    }

    return iconMap;
  }
}
