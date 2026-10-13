import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/persistence/data/services/daisth_database_service.dart';

class RoutineRecordSqliteService {
  const RoutineRecordSqliteService(this.databaseService);

  final DaisthDatabaseService databaseService;

  Future<T> transaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) async {
    final db = await databaseService.open();
    return db.transaction(action);
  }

  Future<Map<String, Object?>?> getRoutineRecord(
    String dateKey,
    String routineId,
  ) async {
    final db = await databaseService.open();
    final rows = await db.query(
      DatabaseSchema.routineRecords,
      where: 'date_key = ? AND routine_id = ?',
      whereArgs: [dateKey, routineId],
      limit: 1,
    );
    return rows.firstOrNull;
  }

  Future<List<Map<String, Object?>>> getStepRecords(
    String dateKey,
    String routineId,
  ) async {
    final db = await databaseService.open();
    return db.query(
      DatabaseSchema.routineStepRecords,
      where: 'date_key = ? AND routine_id = ?',
      whereArgs: [dateKey, routineId],
      orderBy: 'step_id',
    );
  }

  Future<List<Map<String, Object?>>> getRecordsForDay(String dateKey) async {
    final db = await databaseService.open();
    return db.query(
      DatabaseSchema.routineRecords,
      where: 'date_key = ?',
      whereArgs: [dateKey],
      orderBy: 'routine_id',
    );
  }
}
