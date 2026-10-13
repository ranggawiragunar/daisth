import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/persistence/data/services/daisth_database_service.dart';

class ReflectionSqliteService {
  const ReflectionSqliteService(this.databaseService);

  final DaisthDatabaseService databaseService;

  Future<Map<String, Object?>?> get(String dateKey) async {
    final db = await databaseService.open();
    final rows = await db.query(
      DatabaseSchema.dailyReflections,
      where: 'date_key = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    return rows.firstOrNull;
  }

  Future<List<Map<String, Object?>>> getBetween(
    String startDateKey,
    String endDateKey,
  ) async {
    final db = await databaseService.open();
    return db.query(
      DatabaseSchema.dailyReflections,
      where: 'date_key >= ? AND date_key <= ?',
      whereArgs: [startDateKey, endDateKey],
      orderBy: 'date_key DESC',
    );
  }

  Future<String?> getEarliestDateKey() async {
    final db = await databaseService.open();
    final rows = await db.rawQuery(
      'SELECT MIN(date_key) AS earliest FROM ${DatabaseSchema.dailyReflections}',
    );
    return rows.firstOrNull?['earliest'] as String?;
  }

  Future<Map<String, Object?>> save({
    required String dateKey,
    required String rhythm,
    required String? note,
    required DateTime now,
  }) async {
    final db = await databaseService.open();
    final timestamp = now.toUtc().toIso8601String();
    return db.transaction((transaction) async {
      final rows = await transaction.query(
        DatabaseSchema.dailyReflections,
        columns: ['recorded_at_utc'],
        where: 'date_key = ?',
        whereArgs: [dateKey],
        limit: 1,
      );
      final recordedAt = rows.firstOrNull?['recorded_at_utc'] as String?;
      if (recordedAt == null) {
        await transaction.insert(DatabaseSchema.dailyReflections, {
          'date_key': dateKey,
          'rhythm': rhythm,
          'note': note,
          'recorded_at_utc': timestamp,
          'updated_at_utc': timestamp,
        });
      } else {
        await transaction.update(
          DatabaseSchema.dailyReflections,
          {'rhythm': rhythm, 'note': note, 'updated_at_utc': timestamp},
          where: 'date_key = ?',
          whereArgs: [dateKey],
        );
      }
      return (await transaction.query(
        DatabaseSchema.dailyReflections,
        where: 'date_key = ?',
        whereArgs: [dateKey],
        limit: 1,
      )).single;
    });
  }

  Future<bool> delete(String dateKey) async {
    final db = await databaseService.open();
    final deleted = await db.delete(
      DatabaseSchema.dailyReflections,
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
    return deleted > 0;
  }
}
