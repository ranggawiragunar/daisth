import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/persistence/data/services/daisth_database_service.dart';

class RoutineReminderStateSqliteService {
  const RoutineReminderStateSqliteService(this.databaseService);
  final DaisthDatabaseService databaseService;

  Future<Map<String, Object?>?> get(String dateKey, String routineId) async {
    final db = await databaseService.open();
    final rows = await db.query(
      DatabaseSchema.routineReminderStates,
      where: 'date_key = ? AND routine_id = ?',
      whereArgs: [dateKey, routineId],
      limit: 1,
    );
    return rows.firstOrNull;
  }

  Future<List<Map<String, Object?>>> getForDay(String dateKey) async {
    final db = await databaseService.open();
    return db.query(
      DatabaseSchema.routineReminderStates,
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
  }

  Future<void> upsert(Map<String, Object?> row) async {
    final db = await databaseService.open();
    await db.insert(
      DatabaseSchema.routineReminderStates,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String dateKey, String routineId) async {
    final db = await databaseService.open();
    await db.delete(
      DatabaseSchema.routineReminderStates,
      where: 'date_key = ? AND routine_id = ?',
      whereArgs: [dateKey, routineId],
    );
  }
}
