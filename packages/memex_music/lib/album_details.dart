import 'package:memex_music/mpd_controller.dart';
import 'package:memex_ui/memex_ui.dart';

class AlbumInfo {
  Prop<String> artist;
  Prop<String> name;
  Prop<List<String>> tracks = Prop([]);
  Prop<Image?> cover = Prop(null);

  AlbumInfo(
    MpdController mpd, {
    required String artist,
    required String name,
  })  : artist = Prop(artist),
        name = Prop(name) {
    _fetchTracks(mpd);
  }

  _fetchTracks(MpdController mpd) async {
    tracks.value = await mpd.tracksForAlbum(artist.value, name.value);
    final path =
        "${mpd.config.value!.musicDirectory!}/${artist.value}/${name.value}/${tracks.value.first}";
    cover.value = await mpd.fetchCover(path);
  }
}

class AlbumDetails extends ReactiveWidget {
  final String name;
  final String artist;
  const AlbumDetails(this.name, this.artist, {super.key});

  @override
  Widget build(BuildContext context) {
    final mpd = context.state<MpdController>();
    return StateProvider(
      models: [
        () => AlbumInfo(mpd, artist: artist, name: name),
      ],
      builder: (context) {
        final album = context.state<AlbumInfo>();
        return [
          [
            [
              album.name.value.toExtraLargeTitle(),
              album.artist.value.toTitle().textColor(MemexColor.grid),
              const SizedBox(height: 20),
              Button(
                onPressed: () => mpd.addAlbum(artist, album.name.value),
                usePersistentShortcut: true,
                child: "Play all".toText(),
              ),
            ]
                .toColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                )
                .expanded(),
            const SizedBox(width: 20),
            if (album.cover.value != null)
              SizedBox(
                width: 250,
                child: album.cover.value!,
              ).elevation(16)
          ].toRow(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          ),
          const SizedBox(height: 20),
          TreeView(
            items: album.tracks.value.map(
              (track) => TreeViewNode(
                label: track.toSpan(),
                onTap: (_) => mpd.addTrack(artist, album.name.value, track),
              ),
            ),
          ).expanded(),
        ]
            .toColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
            )
            .padding(all: 20);
      },
    );
  }
}
