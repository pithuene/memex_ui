import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components.dart';

class StoryTableDefault extends Story {
  static Prop<bool> showHeader = Prop(true);
  static Prop<bool> fullWidthHighlight = Prop(false);
  static Prop<bool> showEvenRowHighlight = Prop(true);
  static Prop<bool> isActive = Prop(true);

  StoryTableDefault()
      : super(
          name: "Default",
          knobs: [
            KnobSwitch("Show Header", showHeader),
            KnobSwitch("Full Width Highlight", fullWidthHighlight),
            KnobSwitch("Even Row Highlight", showEvenRowHighlight),
            KnobSwitch("Active", isActive),
          ],
        );

  @override
  Widget build(BuildContext context) => ReactiveBuilder(() => TableView(
        rowHeight: 32,
        dataSource: datasource,
        showHeader: showHeader.value,
        fullWidthHighlight: fullWidthHighlight.value,
        showEvenRowHighlight: showEvenRowHighlight.value,
        isActive: isActive,
      ));
}

ComponentExample componentTableView() => ComponentExample(
      name: "TableView",
      stories: [
        StoryTableDefault(),
        /*Story(
          name: "No Header",
          knobs: {
            "noHeader": KnobSwitch(Prop<bool>(false)),
          },
          build: (BuildContext context, knobs) => Column(
            children: [
              Expanded(
                child: TableView(
                  showHeader: knobs["noHeader"] as Prop<bool>,
                  rowHeight: 32,
                  dataSource: datasource,
                ),
              ),
            ],
          ),
        ),
        Story(
          name: "Full Width Highlight",
          build: (BuildContext context, _) => TableView(
            fullWidthHighlight: true,
            rowHeight: 32,
            dataSource: datasource,
          ),
        ),
        Story(
          name: "No even Row Highlight",
          build: (BuildContext context, _) => TableView(
            showEvenRowHighlight: false,
            rowHeight: 32,
            dataSource: datasource,
          ),
        ),*/
      ],
    );

class Person {
  final String firstName;
  final String lastName;
  final int age;
  const Person({
    required this.firstName,
    required this.lastName,
    required this.age,
  });
}

final TableDatasource<Person> datasource = TableDatasource(
  colDefs: [
    ColumnDefinition(
      label: "First name",
      cellBuilder: (BuildContext context, Person content, _) =>
          Text(content.firstName),
    ),
    ColumnDefinition(
      label: "Last name",
      cellBuilder: (BuildContext context, Person content, _) =>
          Text(content.lastName),
    ),
    ColumnDefinition(
      label: "Age",
      cellBuilder: (BuildContext context, Person content, _) =>
          Text(content.age.toString()),
      alignment: ColumnAlignment.end,
    ),
  ],
  getRowCount: () => rows.length,
  getRowValue: (index) => TableValue<Person>(
    key: ObjectKey(rows[index]),
    value: rows[index],
  ),
);

final List<Person> rows = [
  const Person(firstName: "John", lastName: "Smith", age: 34),
  const Person(firstName: "Rosamund", lastName: "Stone", age: 58),
  const Person(firstName: "Missie", lastName: "Ireland", age: 29),
];
