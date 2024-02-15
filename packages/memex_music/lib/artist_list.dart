import 'package:memex_music/main.dart';
import 'package:memex_music/mpd_controller.dart';
import 'package:memex_ui/memex_ui.dart';

class ArtistList extends StatefulWidget {
  const ArtistList({super.key});

  @override
  State<StatefulWidget> createState() => ArtistListState();
}

class ArtistListState extends State<ArtistList> {
  List<String> artists = [];
  late TableDatasource<String> dataSource = TableDatasource(
    colDefs: [
      ColumnDefinition(
        label: "Artist",
        cellBuilder: (context, name, isSelected) => GestureDetector(
          onTap: () => MusicApp.openArtistDetails(name),
          child:
              [name.toText().expanded()].toRow(mainAxisSize: MainAxisSize.max),
        ),
      ),
    ],
    getRowCount: () => artists.length,
    getRowValue: (index) => TableValue(
      key: ValueKey(artists[index]),
      value: artists[index],
    ),
  );

  @override
  void initState() {
    super.initState();
    fetchArtists();
  }

  fetchArtists() async {
    artists = await context.state<MpdController>().artists() ?? [];
    dataSource.dataChanged();
  }

  @override
  Widget build(BuildContext context) => TableView(
        rowHeight: 30,
        dataSource: dataSource,
      );
}
