import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'migrations.dart';

class DbProvider {
  static Database? _db;
  static bool _ffiInitialized = false;

  static Future<Database> instance() async {
    if (_db != null) return _db!;

    if (kIsWeb) {
      throw UnsupportedError(
        'Rogers Tracker needs local SQLite storage, which plain sqflite '
        'does not support on web. Run on desktop or a device instead: '
        'flutter run -d linux',
      );
    }

    if (!_ffiInitialized && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }
    // Android/iOS keep the default sqflite platform-channel factory — no init needed there.

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