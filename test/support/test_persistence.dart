import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:daisth/core/app_settings/data/repositories/app_settings_repository_data.dart';
import 'package:daisth/core/app_settings/data/services/app_settings_sqlite_service.dart';
import 'package:daisth/core/persistence/data/services/daisth_database_service.dart';
import 'package:daisth/features/routines/data/mappers/routine_record_mapper.dart';
import 'package:daisth/features/routines/data/repositories/routine_record_repository_data.dart';
import 'package:daisth/features/routines/data/services/routine_record_sqlite_service.dart';
import 'package:daisth/features/reflection/data/mappers/reflection_mapper.dart';
import 'package:daisth/features/reflection/data/repositories/reflection_repository_data.dart';
import 'package:daisth/features/reflection/data/services/reflection_sqlite_service.dart';

class TestPersistence {
  TestPersistence._(this.directory, this.database, this.databasePath);

  final Directory directory;
  final DaisthDatabaseService database;
  final String databasePath;

  late final routineRecords = RoutineRecordRepositoryData(
    service: RoutineRecordSqliteService(database),
    mapper: RoutineRecordMapper(),
  );
  late final appSettings = AppSettingsRepositoryData(
    service: AppSettingsSqliteService(database),
  );
  late final reflections = ReflectionRepositoryData(
    service: ReflectionSqliteService(database),
    mapper: ReflectionMapper(),
  );

  static Future<TestPersistence> create() async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('daisth-test-');
    final databasePath = path.join(directory.path, 'daisth.db');
    final database = DaisthDatabaseService(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: databasePath,
    );
    await database.open();
    return TestPersistence._(directory, database, databasePath);
  }

  static DaisthDatabaseService createDatabaseServiceAt(String path) {
    sqfliteFfiInit();
    return DaisthDatabaseService(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: path,
    );
  }

  static DaisthDatabaseService createDatabaseService() {
    sqfliteFfiInit();
    return DaisthDatabaseService(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: path.join(
        Directory.systemTemp.path,
        'daisth-widget-${DateTime.now().microsecondsSinceEpoch}-${Object().hashCode}.db',
      ),
    );
  }

  Future<void> dispose() async {
    await routineRecords.closeChanges();
    await reflections.closeChanges();
    await database.close();
    await directory.delete(recursive: true);
  }
}
