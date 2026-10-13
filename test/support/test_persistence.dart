import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:istiqam/core/app_settings/data/repositories/app_settings_repository_data.dart';
import 'package:istiqam/core/app_settings/data/services/app_settings_sqlite_service.dart';
import 'package:istiqam/core/persistence/data/services/istiqam_database_service.dart';
import 'package:istiqam/features/routines/data/mappers/routine_record_mapper.dart';
import 'package:istiqam/features/routines/data/repositories/routine_record_repository_data.dart';
import 'package:istiqam/features/routines/data/services/routine_record_sqlite_service.dart';

class TestPersistence {
  TestPersistence._(this.directory, this.database, this.databasePath);

  final Directory directory;
  final IstiqamDatabaseService database;
  final String databasePath;

  late final routineRecords = RoutineRecordRepositoryData(
    service: RoutineRecordSqliteService(database),
    mapper: RoutineRecordMapper(),
  );
  late final appSettings = AppSettingsRepositoryData(
    service: AppSettingsSqliteService(database),
  );

  static Future<TestPersistence> create() async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('istiqam-test-');
    final databasePath = path.join(directory.path, 'istiqam.db');
    final database = IstiqamDatabaseService(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: databasePath,
    );
    await database.open();
    return TestPersistence._(directory, database, databasePath);
  }

  static IstiqamDatabaseService createDatabaseServiceAt(String path) {
    sqfliteFfiInit();
    return IstiqamDatabaseService(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: path,
    );
  }

  static IstiqamDatabaseService createDatabaseService() {
    sqfliteFfiInit();
    return IstiqamDatabaseService(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: path.join(
        Directory.systemTemp.path,
        'istiqam-widget-${DateTime.now().microsecondsSinceEpoch}-${Object().hashCode}.db',
      ),
    );
  }

  Future<void> dispose() async {
    await routineRecords.closeChanges();
    await database.close();
    await directory.delete(recursive: true);
  }
}
