import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:isar/isar.dart';
import 'package:memex_data/memex_data.dart';

import './user.dart';

void main() async {
  await Isar.initializeIsarCore(download: true);
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('memex_data');
  });

  tearDownAll(() async {
    await dir.delete(recursive: true);
  });

  test('adds one to input values', () async {
    final isar = await Isar.open(
      [UserSchema],
      directory: dir.path,
    );

    final newUser = User()
      ..name = 'Jane Doe'
      ..age = 36;

    await isar.writeTxn(() async {
      await isar.users.put(newUser); // insert & update
    });

    final existingUser = (await isar.users.get(newUser.id))!;

    expect(existingUser.age, 36);

    await isar.writeTxn(() async {
      await isar.users.delete(existingUser.id); // delete
    });
  });
}
