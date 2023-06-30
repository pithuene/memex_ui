import 'package:flutter/widgets.dart';
import 'package:memex_ui/memex_ui.dart';
import 'package:memex_ui_examples/components.dart';

ComponentExample componentTableView = ComponentExample(
  name: "TableView",
  stories: [
    Story(
      "Default",
      (BuildContext context) => TableView(
        rowHeight: 32,
        dataSource: datasource,
      ),
    ),
    Story(
      "No Header",
      (BuildContext context) => TableView(
        showHeader: false,
        rowHeight: 32,
        dataSource: datasource,
      ),
    ),
    Story(
      "Full Width Highlight",
      (BuildContext context) => TableView(
        fullWidthHighlight: true,
        rowHeight: 32,
        dataSource: datasource,
      ),
    ),
    Story(
      "No even Row Highlight",
      (BuildContext context) => TableView(
        showEvenRowHighlight: false,
        rowHeight: 32,
        dataSource: datasource,
      ),
    ),
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
      cellBuilder: (BuildContext context, Person content) =>
          Text(content.firstName),
    ),
    ColumnDefinition(
      label: "Last name",
      cellBuilder: (BuildContext context, Person content) =>
          Text(content.lastName),
    ),
    ColumnDefinition(
      label: "Age",
      cellBuilder: (BuildContext context, Person content) =>
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
