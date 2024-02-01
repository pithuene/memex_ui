import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  String? name;

  int? age;

  Future<void> save(Isar isar) async => await isar.writeTxn(() async {
        await isar.users.put(this);
      });

  static Future<User?> get(Isar isar, int id) async => isar.users.get(id);
}
