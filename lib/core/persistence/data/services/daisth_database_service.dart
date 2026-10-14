import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../schema/database_schema.dart';

class DaisthDatabaseService {
  DaisthDatabaseService({this.factory, this.databasePath})
    : _singleInstance = true;

  // A notification isolate must own its native connection. Closing it must
  // never close the foreground engine's connection to the same SQLite file.
  DaisthDatabaseService.background({this.factory, this.databasePath})
    : _singleInstance = false;

  static const databaseName = 'daisth.db';

  final DatabaseFactory? factory;
  final String? databasePath;
  final bool _singleInstance;
  Future<Database>? _database;

  Future<Database> open() => _database ??= _open();

  Future<Database> _open() async {
    final resolvedFactory = factory ?? databaseFactory;
    final resolvedPath =
        databasePath ??
        path.join(await resolvedFactory.getDatabasesPath(), databaseName);
    return resolvedFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: DatabaseSchema.version,
        singleInstance: _singleInstance,
        onCreate: (db, _) => DatabaseSchema.create(db),
        onUpgrade: DatabaseSchema.upgrade,
      ),
    );
  }

  Future<void> close() async {
    final databaseFuture = _database;
    _database = null;
    if (databaseFuture == null) return;
    try {
      await (await databaseFuture).close();
    } catch (_) {
      // Preserve open/migration failures; closing an unopened database is safe.
    }
  }
}
