import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:memex_music/album_details.dart';
import 'package:memex_music/artist_details.dart';
import 'package:memex_music/artist_list.dart';
import 'package:memex_music/mpd_controller.dart';
import 'package:memex_ui/memex_ui.dart';

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  static void openArtistList() {
    App.navigator.push(CupertinoPageRoute(
      builder: (context) => buildPage(
        context,
        const ArtistList(),
      ),
    ));
  }

  static void openArtistDetails(String artistName) {
    App.navigator.push(CupertinoPageRoute(
      builder: (context) => buildPage(
        context,
        ArtistDetails(artistName),
      ),
    ));
  }

  static void openAlbumDetails(String artist, String album) {
    App.navigator.push(CupertinoPageRoute(
      builder: (context) => buildPage(
        context,
        AlbumDetails(
          album,
          artist,
        ),
      ),
    ));
  }

  static buildPage(BuildContext context, Widget content) {
    return [
      content.backgroundColor(MemexColor.white).expanded(),
      const BottomBarControl(),
    ].toColumn();
  }

  @override
  Widget build(BuildContext context) => StateProvider(
        models: [
          () => MpdController(),
        ],
        builder: (context) => App(
          appName: "Music Player",
          shortcuts: {
            LogicalKeySet(
              LogicalKeyboardKey.space,
            ): VoidCallbackIntent(() => context.state<MpdController>().pause()),
            LogicalKeySet(
              LogicalKeyboardKey.shift,
              LogicalKeyboardKey.keyH,
            ): VoidCallbackIntent(() => App.navigator.maybePop()),
          },
          toolBar: ToolBar(
            title: "Music".toText(),
            leading: MacosIconButton(
              icon: const MemexIcon(CupertinoIcons.chevron_back),
              onPressed: () => App.navigator.maybePop(),
            ),
          ),
          sidebar: Sidebar(
            topOffset: 0,
            builder: (context, scrollController) => [
              TreeView(items: [
                TreeViewNode(
                  label: const TextSpan(text: "Artists"),
                  onTap: (_) => openArtistList(),
                ),
                TreeViewNode(
                  label: const TextSpan(text: "Artist"),
                  onTap: (_) => openArtistDetails("Lorde"),
                ),
              ]).expanded(),
              const CurrentlyPlaying().padding(bottom: 20),
            ].toColumn(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
            ),
            minWidth: 250,
          ),
          builder: (context, _) => buildPage(context, const ArtistList()),
        ),
      );
}

class BottomBarControl extends ReactiveWidget {
  const BottomBarControl({super.key});

  @override
  Widget build(BuildContext context) {
    final mpd = context.state<MpdController>();
    return [
      [
        MacosIconButton(
          onPressed: () async {
            await mpd.previousSong();
          },
          icon: const MemexIcon(CupertinoIcons.backward_end, size: 24),
        ),
        MacosIconButton(
          onPressed: () => mpd.pause(),
          icon: const MemexIcon(CupertinoIcons.pause, size: 24),
        ),
        MacosIconButton(
          onPressed: () async {
            await mpd.nextSong();
          },
          icon: const MemexIcon(CupertinoIcons.forward_end, size: 24),
        )
      ].toRow(mainAxisAlignment: MainAxisAlignment.center).padding(top: 20),
      MacosSlider(
        value: mpd.progess.toDouble(),
        onChanged: (progress) {
          // mpd.seek(progress);
        },
        min: 0,
        max: 100,
      ).padding(all: 20),
    ]
        .toColumn(mainAxisSize: MainAxisSize.min)
        .border(top: 1, color: MemexColor.grid)
        .backgroundColor(MemexColor.white);
  }
}

class CurrentlyPlaying extends ReactiveWidget {
  const CurrentlyPlaying({super.key});

  @override
  Widget build(BuildContext context) {
    final mpd = context.state<MpdController>();

    final title = mpd.currentSong.value?.title?.join(" ") ??
        mpd.currentSong.value?.file ??
        "Not playing";

    return [
      FutureBuilder(
        future: mpd.fetchCoverForCurrentSong(),
        builder: (context, data) =>
            data.hasData ? data.data! : "Loading".toText(),
      ).elevation(8),
      const SizedBox(height: 12),
      title.toTitle(),
      (mpd.currentSong.value?.artist?.join(" ") ?? "").toText(),
    ]
        .toColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
        )
        .padding(all: 20);
  }
}
