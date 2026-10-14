import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/persistence/data/services/daisth_database_service.dart';
import '../../../sync/data/services/sync_outbox_sqlite_helper.dart';
import '../../domain/models/routine_content.dart';
import '../../domain/repositories/routine_content_repository.dart';
import '../mappers/routine_content_mapper.dart';

class RoutineContentRepositoryData implements RoutineContentRepository {
  RoutineContentRepositoryData({
    required this.database,
    this.mapper = const RoutineContentMapper(),
  });

  final DaisthDatabaseService database;
  final RoutineContentMapper mapper;

  @override
  Future<RoutineContent?> getForRoutine(String routineId) async {
    final db = await database.open();
    final rows = await db.query(
      DatabaseSchema.routineContents,
      where: 'routine_id = ?',
      whereArgs: [routineId],
      limit: 1,
    );
    return rows.isEmpty ? null : mapper.fromMap(rows.single);
  }

  @override
  Future<void> save(RoutineContent content) async {
    final db = await database.open();
    await db.transaction((tx) async {
      await tx.insert(
        DatabaseSchema.routineContents,
        mapper.toMap(content),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await SyncOutboxSqliteHelper.enqueueLocalMutation(
        tx,
        entityType: 'routineContent',
        entityKey: Uri.encodeComponent(content.routineId),
        operation: 'upsert',
        changedAtUtc: content.updatedAt,
      );
    });
    SyncOutboxSqliteHelper.notifyLocalMutation();
  }

  @override
  Future<void> deleteForRoutine(
    String routineId, {
    required DateTime now,
  }) async {
    final db = await database.open();
    await db.transaction((tx) async {
      await tx.delete(
        DatabaseSchema.routineContents,
        where: 'routine_id = ?',
        whereArgs: [routineId],
      );
      await SyncOutboxSqliteHelper.enqueueLocalMutation(
        tx,
        entityType: 'routineContent',
        entityKey: Uri.encodeComponent(routineId),
        operation: 'delete',
        changedAtUtc: now,
      );
    });
    SyncOutboxSqliteHelper.notifyLocalMutation();
  }
}
