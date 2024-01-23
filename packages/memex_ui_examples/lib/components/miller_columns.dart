import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui/miller_columns/directory_explorer.dart';
import 'package:memex_ui/miller_columns/miller_columns.dart';
import 'package:memex_ui_examples/components.dart';

class City {
  final String name;
  final List<(City, int)> connections;
  const City(this.name, this.connections);

  static City hannover = City("Hannover", [
    (magdeburg, 100),
    (bremen, 150),
    (osnabrueck, 100),
  ]);
  static City magdeburg = City("Magdeburg", [
    (potsdam, 150),
  ]);
  static City potsdam = City("Potsdam", [(berlin, 50)]);
  static City berlin = const City("Berlin", []);
  static City bremen = City("Bremen", [
    (hamburg, 100),
  ]);
  static City hamburg = const City("Hamburg", []);
  static City osnabrueck = City("Osnabrück", [
    (muenster, 100),
  ]);
  static City muenster = City("Münster", [
    (dortmund, 100),
  ]);
  static City dortmund = const City("Dortmund", []);
}

class StoryMillerColumnsCities extends Story {
  StoryMillerColumnsCities()
      : super(
          name: "Cities",
          knobs: [],
        );

  @override
  Widget build(BuildContext context) => MillerColumns<int, City>(
        columnCount: 3,
        rootNode: City.hannover,
        getChildren: (City city) async => city.connections.isEmpty
            ? null
            : city.connections
                .mapIndexedAndLast((idx, conn, _) => NodeAndKey(conn.$1, idx)),
        rowBuilder: (BuildContext context, City city, _) => Text(city.name),
      );
}

class StoryMillerColumnsDirectoryExplorer extends Story {
  StoryMillerColumnsDirectoryExplorer()
      : super(
          name: "Directory Explorer",
          knobs: [],
        );

  @override
  Widget build(BuildContext context) => const DirectoryExplorer(
        showHidden: false,
      );
}

ComponentExample componentMillerColumns() => ComponentExample(
      name: "Miller Columns",
      stories: [
        StoryMillerColumnsCities(),
        StoryMillerColumnsDirectoryExplorer(),
      ],
    );
