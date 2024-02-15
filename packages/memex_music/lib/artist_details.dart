import 'package:memex_music/main.dart';
import 'package:memex_music/mpd_controller.dart';
import 'package:memex_ui/memex_ui.dart';

class ArtistInfo {
  Prop<String> name;
  Prop<List<String>> albums = Prop([]);

  ArtistInfo(
    MpdController mpd, {
    required String name,
  }) : name = Prop(name) {
    _fetchAlbums(mpd);
  }

  _fetchAlbums(MpdController mpd) async {
    albums.value = await mpd.albumsForArtist(name.value) ?? [];
  }
}

class ArtistDetails extends ReactiveWidget {
  final String name;
  const ArtistDetails(this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    final mpd = context.state<MpdController>();
    return StateProvider(
      models: [
        () => ArtistInfo(mpd, name: name),
      ],
      builder: (context) {
        final artist = context.state<ArtistInfo>();
        return [
          artist.name.value.toExtraLargeTitle(),
          const SizedBox(height: 20),
          TreeView(
            items: artist.albums.value.map(
              (albumName) => TreeViewNode(
                label: albumName.toSpan(),
                onTap: (_) => MusicApp.openAlbumDetails(
                  artist.name.value,
                  albumName,
                ),
              ),
            ),
          ).expanded(),
        ]
            .toColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            )
            .padding(all: 20);
      },
    );
  }
}
