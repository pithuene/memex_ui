import 'dart:io';

import 'package:dart_mpd/dart_mpd.dart';
import 'package:flutter/foundation.dart';
import 'package:id3tag/id3tag.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:logging/logging.dart';

final log = Logger("memex_music_mpd");

class MpdController {
  final _idleClient =
      MpdClient(connectionDetails: MpdConnectionDetails.resolve());
  final _client = MpdClient(connectionDetails: MpdConnectionDetails.resolve());

  Prop<MpdSong?> currentSong = Prop(null);
  Prop<MpdStatus?> status = Prop(null);
  Prop<MpdConfig?> config = Prop(null);

  MpdController() {
    run();
  }

  void run() async {
    config.value = await _idleClient.config();
    while (true) {
      final newSong = await _idleClient.currentsong();
      if (currentSong.value != newSong) {
        currentSong.value = newSong;
        fetchCoverForCurrentSong();
      }
      status.value = await _idleClient.status();
      final changes = await _idleClient.idle();
      log.fine("Idle changes: $changes");
    }
  }

  int get progess => status.value?.elapsed != null
      ? (status.value!.elapsed! / status.value!.duration! * 100).toInt()
      : 0;

  Future<void> seek(double progress) async {
    await _client.seek(
      status.value!.song!,
      status.value!.duration! * progess,
    );
  }

  Future<void> pause() async {
    await _client.pause();
  }

  Future<void> previousSong() async {
    await _client.previous();
  }

  Future<void> nextSong() async {
    await _client.next();
  }

  Future<List<String>?> artists() async {
    // final response = await _client.list('albumartist');
    // return response[0]["AlbumArtist"];

    if (config.value?.musicDirectory != null) {
      final artistDirs = Directory(config.value!.musicDirectory!).list();
      return (await artistDirs
          .where((dir) => dir is Directory)
          .map((dir) => dir.path.split("/").last)
          .where((dirName) => dirName[0] != '.')
          .toList())
        ..sort();
    }
    return [];
  }

  Future<List<String>?> albumsForArtist(String artist) async {
    if (config.value?.musicDirectory != null) {
      final albumDirs =
          Directory("${config.value!.musicDirectory!}/$artist").list();
      return albumDirs
          .where((dir) => dir is Directory)
          .map((dir) => dir.path.split("/").last)
          .where((dirName) => dirName[0] != '.')
          .toList();
    }
    return [];

    // final response = await _client.list(
    //   'album',
    //   filter: "albumartist \"$artist\"",
    // );
    // return response[0]["Album"];*/
  }

  Future<List<String>> tracksForAlbum(String artist, String album) async {
    if (config.value?.musicDirectory != null) {
      final trackFiles =
          Directory("${config.value!.musicDirectory!}/$artist/$album").list();
      return trackFiles
          .where((file) => file is File)
          .map((file) => file.path.split("/").last)
          .where((name) => name[0] != '.')
          .toList();
    }
    return [];
    // final response = await _client.list(
    //  'title',
    //   filter: "albumartist \"$artist\" album \"$album\"",
    //);
    // return response[0]["Title"];
  }

  Future<Image?> fetchCover(String filePath) async {
    // TODO Use _client.readpicture
    final parser = ID3TagReader.path(filePath);
    final tag = parser.readTagSync();
    return Image.memory(
      Uint8List.fromList(tag.pictures.first.imageData),
    );
  }

  Future<Image?> fetchCoverForCurrentSong() async {
    if (currentSong.value?.file != null) {
      final filePath =
          "${config.value!.musicDirectory}/${currentSong.value!.file}";
      return await fetchCover(filePath);
    } else {
      return null;
    }
  }

  String _albumPath(String artist, String album) => "\"$artist/$album\"";

  String _trackPath(String artist, String album, String track) =>
      "\"$artist/$album/$track\"";

  addTrack(String artist, String album, String track) async {
    // Add the track to the queue
    final path = _trackPath(artist, album, track);
    log.info("addTrack $path");
    await _client.add(path);
    // Play the last song of the queue (should be the one just added)
    final playlist = await _client.playlistinfo();
    _client.play(playlist.length - 1);
  }

  addAlbum(String artist, String album) async {
    final oldPlaylist = await _client.playlistinfo();
    // Add all songs to the queue recursively
    final path = _albumPath(artist, album);
    log.info("addAlbum $path");
    await _client.add(path);
    // Begin playing the first added song.
    _client.play(oldPlaylist.length);
  }
}
