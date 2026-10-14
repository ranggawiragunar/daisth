import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/persistence/data/services/daisth_database_service.dart';
import '../../../sync/data/services/sync_outbox_sqlite_helper.dart';
import '../../domain/models/routine_attachment.dart';
import '../../domain/repositories/routine_attachment_repository.dart';
import '../mappers/routine_attachment_mapper.dart';

class RoutineAttachmentRepositoryData implements RoutineAttachmentRepository {
  RoutineAttachmentRepositoryData({
    required this.database,
    this.mapper = const RoutineAttachmentMapper(),
  });

  final DaisthDatabaseService database;
  final RoutineAttachmentMapper mapper;

  @override
  Future<List<RoutineAttachment>> listForRoutine(String routineId) async {
    final db = await database.open();
    return (await db.query(
      DatabaseSchema.routineAttachments,
      where: 'routine_id = ? AND deleted_at_utc IS NULL',
      whereArgs: [routineId],
      orderBy: 'sort_order ASC, created_at_utc ASC',
    )).map(mapper.fromMap).toList(growable: false);
  }

  @override
  Future<Set<String>> getAllLocalRelativePaths() async {
    final db = await database.open();
    final rows = await db.query(
      DatabaseSchema.routineAttachments,
      columns: ['local_relative_path'],
      where: 'local_relative_path IS NOT NULL',
    );
    return rows.map((row) => row['local_relative_path'] as String).toSet();
  }

  @override
  Future<void> saveAll(List<RoutineAttachment> attachments) async {
    if (attachments.isEmpty) return;
    final db = await database.open();
    await db.transaction((tx) async {
      for (final attachment in attachments) {
        await tx.insert(
          DatabaseSchema.routineAttachments,
          mapper.toMap(attachment),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await SyncOutboxSqliteHelper.enqueueLocalMutation(
          tx,
          entityType: 'routineAttachment',
          entityKey: Uri.encodeComponent(attachment.id),
          operation: 'upsert',
          changedAtUtc: attachment.updatedAt,
        );
      }
    });
    SyncOutboxSqliteHelper.notifyLocalMutation();
  }

  @override
  Future<void> applyRemote(RoutineAttachment attachment) async {
    final db = await database.open();
    await db.insert(
      DatabaseSchema.routineAttachments,
      mapper.toMap(attachment),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
