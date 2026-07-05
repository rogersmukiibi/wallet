import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'migrations.dart';

class DbProvider {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = join(dir, 'rogers_tracker.db');
    final versions = migrations.keys.toList()..sort();

    _db = await openDatabase(
      path,
      version: versions.last,
      onCreate: (db, version) async {
        for (final v in versions) {
          for (final stmt in migrations[v]!) {
            await db.execute(stmt);
          }
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        for (final v in versions) {
          if (v > oldVersion) {
            for (final stmt in migrations[v]!) {
              await db.execute(stmt);
            }
          }
        }
      },
    );
    return _db!;
  }
}