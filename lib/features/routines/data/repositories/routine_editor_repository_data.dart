import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/persistence/data/services/daisth_database_service.dart';
import '../../../sync/data/mappers/firestore_document_ids.dart';
import '../../../sync/data/services/sync_outbox_sqlite_helper.dart';
import '../../domain/models/routine_editor_save.dart';
import '../../domain/repositories/routine_editor_repository.dart';
import '../mappers/routine_attachment_mapper.dart';
import '../mappers/routine_content_mapper.dart';
import '../mappers/routine_definition_mapper.dart';

class RoutineEditorRepositoryData implements RoutineEditorRepository {
  RoutineEditorRepositoryData({
    required this.database,
    required this.onRoutineChanged,
    this.definitionMapper = const RoutineDefinitionMapper(),
    this.contentMapper = const RoutineContentMapper(),
    this.attachmentMapper = const RoutineAttachmentMapper(),
  });

  final DaisthDatabaseService database;
  final void Function() onRoutineChanged;
  final RoutineDefinitionMapper definitionMapper;
  final RoutineContentMapper contentMapper;
  final RoutineAttachmentMapper attachmentMapper;

  @override
  Future<void> save(RoutineEditorSave value) async {
    final db = await database.open();
    final now = value.now.toUtc();
    await db.transaction((tx) async {
      await tx.insert(
        DatabaseSchema.routineDefinitions,
        definitionMapper.toMap(value.definition),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _enqueue(
        tx,
        type: 'routineDefinition',
        key: FirestoreDocumentIds.routineDefinition(value.definition.id),
        at: value.definition.updatedAt,
      );

      if (value.steps != null) await _saveSteps(tx, value);

      final previousContent = await tx.query(
        DatabaseSchema.routineContents,
        where: 'routine_id = ?',
        whereArgs: [value.definition.id],
        limit: 1,
      );
      if (value.content == null) {
        if (previousContent.isNotEmpty) {
          await tx.delete(
            DatabaseSchema.routineContents,
            where: 'routine_id = ?',
            whereArgs: [value.definition.id],
          );
          await _enqueue(
            tx,
            type: 'routineContent',
            key: Uri.encodeComponent(value.definition.id),
            at: now,
            operation: 'delete',
          );
        }
      } else {
        final content = value.content!;
        await tx.insert(
          DatabaseSchema.routineContents,
          contentMapper.toMap(content),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        if (previousContent.isEmpty ||
            previousContent.single['delta_json'] != content.serializedDelta) {
          await _enqueue(
            tx,
            type: 'routineContent',
            key: Uri.encodeComponent(value.definition.id),
            at: content.updatedAt,
          );
        }
      }

      final currentRows = await tx.query(
        DatabaseSchema.routineAttachments,
        where: 'routine_id = ? AND deleted_at_utc IS NULL',
        whereArgs: [value.definition.id],
      );
      final currentIds = currentRows.map((row) => row['id'] as String).toSet();
      for (final id in value.removedAttachmentIds.intersection(currentIds)) {
        await tx.update(
          DatabaseSchema.routineAttachments,
          {
            'local_relative_path': null,
            'updated_at_utc': now.toIso8601String(),
            'deleted_at_utc': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await _enqueue(
          tx,
          type: 'routineAttachment',
          key: Uri.encodeComponent(id),
          at: now,
          operation: 'delete',
        );
      }
      for (final attachment in value.attachments) {
        await tx.insert(
          DatabaseSchema.routineAttachments,
          attachmentMapper.toMap(attachment),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        final old = currentRows.where((row) => row['id'] == attachment.id);
        if (old.isEmpty ||
            old.single['sort_order'] != attachment.sortOrder ||
            old.single['content_sha256'] != attachment.contentSha256) {
          await _enqueue(
            tx,
            type: 'routineAttachment',
            key: Uri.encodeComponent(attachment.id),
            at: attachment.updatedAt,
          );
        }
      }
    });
    onRoutineChanged();
    SyncOutboxSqliteHelper.notifyLocalMutation();
  }

  Future<void> _saveSteps(Transaction tx, RoutineEditorSave value) async {
    final routineId = value.definition.id;
    final steps = value.steps!;
    final current = await tx.query(
      DatabaseSchema.routineStepDefinitions,
      where: 'routine_id = ? AND is_archived = 0',
      whereArgs: [routineId],
    );
    final activeIds = steps.map((step) => step.stepId).toSet();
    for (final row in current) {
      final id = row['step_id'] as String;
      if (activeIds.contains(id)) continue;
      await tx.update(
        DatabaseSchema.routineStepDefinitions,
        {
          'is_archived': 1,
          'updated_at_utc': value.now.toUtc().toIso8601String(),
        },
        where: 'routine_id = ? AND step_id = ?',
        whereArgs: [routineId, id],
      );
      await _enqueue(
        tx,
        type: 'routineStepDefinition',
        key: FirestoreDocumentIds.routineStepDefinition(routineId, id),
        at: value.now,
      );
    }
    for (final step in steps) {
      await tx.insert(
        DatabaseSchema.routineStepDefinitions,
        definitionMapper.stepToMap(step),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _enqueue(
        tx,
        type: 'routineStepDefinition',
        key: FirestoreDocumentIds.routineStepDefinition(
          step.routineId,
          step.stepId,
        ),
        at: step.updatedAt,
      );
    }
  }

  Future<void> _enqueue(
    Transaction tx, {
    required String type,
    required String key,
    required DateTime at,
    String operation = 'upsert',
  }) => SyncOutboxSqliteHelper.enqueueLocalMutation(
    tx,
    entityType: type,
    entityKey: key,
    operation: operation,
    changedAtUtc: at,
  );
}
