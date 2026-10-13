import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/persistence/data/services/daisth_database_service.dart';

class RoutineSqliteService {
  const RoutineSqliteService(this.databaseService);
  final DaisthDatabaseService databaseService;

  Future<T> transaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) async => (await databaseService.open()).transaction(action);

  Future<Map<String, Object?>?> getRoutine(String id) async {
    final rows = await (await databaseService.open()).query(
      DatabaseSchema.routineDefinitions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.firstOrNull;
  }

  Future<List<Map<String, Object?>>> getRoutines({
    required bool includeArchived,
  }) async {
    final db = await databaseService.open();
    return db.query(
      DatabaseSchema.routineDefinitions,
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'sort_order, created_at_utc, id',
    );
  }

  Future<List<Map<String, Object?>>> getAllRoutines() async =>
      (await databaseService.open()).query(
        DatabaseSchema.routineDefinitions,
        orderBy: 'sort_order, created_at_utc, id',
      );

  Future<String?> getEarliestRoutineCreatedAt() async {
    final rows = await (await databaseService.open()).rawQuery(
      'SELECT MIN(created_at_utc) AS earliest FROM '
      '${DatabaseSchema.routineDefinitions}',
    );
    return rows.firstOrNull?['earliest'] as String?;
  }

  Future<List<Map<String, Object?>>> getSteps(String routineId) async =>
      (await databaseService.open()).query(
        DatabaseSchema.routineStepDefinitions,
        where: 'routine_id = ? AND is_archived = 0',
        whereArgs: [routineId],
        orderBy: 'sort_order, created_at_utc, step_id',
      );

  Future<List<Map<String, Object?>>> getAllSteps(String routineId) async =>
      (await databaseService.open()).query(
        DatabaseSchema.routineStepDefinitions,
        where: 'routine_id = ?',
        whereArgs: [routineId],
        orderBy: 'sort_order, created_at_utc, step_id',
      );

  Future<List<Map<String, Object?>>> getAllStepDefinitions() async =>
      (await databaseService.open()).query(
        DatabaseSchema.routineStepDefinitions,
        orderBy: 'routine_id, sort_order, created_at_utc, step_id',
      );
}
