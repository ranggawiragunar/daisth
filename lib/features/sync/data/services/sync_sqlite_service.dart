import 'dart:convert';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/persistence/data/services/daisth_database_service.dart';
import '../../../reflection/data/mappers/reflection_mapper.dart';
import '../../../reflection/domain/models/daily_reflection.dart';
import '../../../routines/data/mappers/routine_definition_mapper.dart';
import '../../../routines/data/mappers/routine_record_mapper.dart';
import '../../../routines/data/models/routine_record_data.dart';
import '../../../routines/data/models/routine_step_record_data.dart';
import '../../../routines/domain/models/routine_definition.dart';
import '../../../routines/domain/models/routine_record.dart';
import '../../../routines/domain/models/routine_step_definition.dart';
import '../../../routines/domain/models/routine_step_record.dart';
import '../../domain/models/sync_entity.dart';
import '../mappers/firestore_document_ids.dart';
import '../mappers/sync_entity_firestore_mapper.dart';

class SyncSqliteService {
  SyncSqliteService(this.databaseService);

  final DaisthDatabaseService databaseService;
  final _definitionMapper = RoutineDefinitionMapper();
  final _recordMapper = RoutineRecordMapper();
  final _reflectionMapper = ReflectionMapper();
  final _entityMapper = SyncEntityFirestoreMapper();

  Future<SyncState> initialize() async {
    final db = await databaseService.open();
    final rows = await db.query(DatabaseSchema.syncMetadata, where: 'id = 1');
    if (rows.isEmpty) {
      final now = DateTime.now().toUtc().toIso8601String();
      await db.insert(DatabaseSchema.syncMetadata, {
        'id': 1,
        'device_id': _newDeviceId(),
        'created_at_utc': now,
        'updated_at_utc': now,
      });
    }
    return getState();
  }

  Future<SyncState> getState() async {
    final db = await databaseService.open();
    final row = (await db.query(
      DatabaseSchema.syncMetadata,
      where: 'id = 1',
      limit: 1,
    )).first;
    final pending = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DatabaseSchema.syncOutbox}',
    );
    return SyncState(
      deviceId: row['device_id'] as String,
      linkedUid: row['linked_uid'] as String?,
      initialSyncCompleted: row['initial_sync_completed'] == 1,
      pendingCount: pending.first['count'] as int,
      lastAttemptAtUtc: _date(row['last_attempt_at_utc']),
      lastSuccessfulSyncAtUtc: _date(row['last_successful_sync_at_utc']),
      lastErrorCode: row['last_error_code'] as String?,
    );
  }

  Future<List<SyncEntity>> getSnapshot() async {
    final db = await databaseService.open();
    final state = await getState();
    final result = <SyncEntity>[];
    for (final row in await db.query(DatabaseSchema.routineDefinitions)) {
      result.add(
        _entityMapper.routineDefinition(
          _definitionMapper.fromMap(row),
          state.deviceId,
        ),
      );
    }
    for (final row in await db.query(DatabaseSchema.routineStepDefinitions)) {
      result.add(
        _entityMapper.routineStepDefinition(
          _definitionMapper.stepFromMap(row),
          state.deviceId,
        ),
      );
    }
    for (final row in await db.query(DatabaseSchema.routineRecords)) {
      result.add(
        _entityMapper.routineRecord(
          _recordMapper.fromData(RoutineRecordData.fromMap(row)),
          state.deviceId,
        ),
      );
    }
    for (final row in await db.query(DatabaseSchema.routineStepRecords)) {
      result.add(
        _entityMapper.routineStepRecord(
          _recordMapper.stepFromData(RoutineStepRecordData.fromMap(row)),
          state.deviceId,
        ),
      );
    }
    for (final row in await db.query(DatabaseSchema.dailyReflections)) {
      result.add(
        _entityMapper.dailyReflection(
          _reflectionMapper.fromData(row),
          state.deviceId,
        ),
      );
    }
    return result;
  }

  Future<SyncEntity?> getEntity(
    SyncEntityType type,
    String key,
    String deviceId,
  ) async {
    final db = await databaseService.open();
    Map<String, Object?>? row;
    switch (type) {
      case SyncEntityType.routineDefinition:
        row = await _one(db, DatabaseSchema.routineDefinitions, 'id = ?', [
          Uri.decodeComponent(key),
        ]);
        return row == null
            ? null
            : _entityMapper.routineDefinition(
                _definitionMapper.fromMap(row),
                deviceId,
              );
      case SyncEntityType.routineStepDefinition:
        final parts = FirestoreDocumentIds.splitPair(key);
        row = await _one(
          db,
          DatabaseSchema.routineStepDefinitions,
          'routine_id = ? AND step_id = ?',
          [parts.$1, parts.$2],
        );
        return row == null
            ? null
            : _entityMapper.routineStepDefinition(
                _definitionMapper.stepFromMap(row),
                deviceId,
              );
      case SyncEntityType.routineRecord:
        final parts = FirestoreDocumentIds.splitPair(key);
        row = await _one(
          db,
          DatabaseSchema.routineRecords,
          'date_key = ? AND routine_id = ?',
          [parts.$1, parts.$2],
        );
        return row == null
            ? null
            : _entityMapper.routineRecord(
                _recordMapper.fromData(RoutineRecordData.fromMap(row)),
                deviceId,
              );
      case SyncEntityType.routineStepRecord:
        final parts = FirestoreDocumentIds.splitTriple(key);
        row = await _one(
          db,
          DatabaseSchema.routineStepRecords,
          'date_key = ? AND routine_id = ? AND step_id = ?',
          [parts.$1, parts.$2, parts.$3],
        );
        return row == null
            ? null
            : _entityMapper.routineStepRecord(
                _recordMapper.stepFromData(RoutineStepRecordData.fromMap(row)),
                deviceId,
              );
      case SyncEntityType.dailyReflection:
        row = await _one(db, DatabaseSchema.dailyReflections, 'date_key = ?', [
          key,
        ]);
        return row == null
            ? null
            : _entityMapper.dailyReflection(
                _reflectionMapper.fromData(row),
                deviceId,
              );
    }
  }

  Future<List<SyncOutboxOperation>> getPending({int limit = 400}) async {
    final db = await databaseService.open();
    final rows = await db.query(
      DatabaseSchema.syncOutbox,
      orderBy: 'changed_at_utc ASC',
      limit: limit,
    );
    return rows
        .map(
          (row) => SyncOutboxOperation(
            type: SyncEntityTypeStorage.fromStorage(
              row['entity_type'] as String,
            )!,
            entityKey: row['entity_key'] as String,
            operation: (row['operation'] as String) == 'delete'
                ? SyncOperation.delete
                : SyncOperation.upsert,
            changedAtUtc: DateTime.parse(
              row['changed_at_utc'] as String,
            ).toUtc(),
            attemptCount: row['attempt_count'] as int,
            lastErrorCode: row['last_error_code'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<List<SyncEntity>> applyMerge({
    required List<SyncEntity> remoteWinners,
    required List<SyncEntity> localWinners,
    required DateTime nowUtc,
    String? linkedUid,
    bool markInitialSyncComplete = false,
  }) async {
    final db = await databaseService.open();
    return db.transaction((tx) async {
      final metadata = (await tx.query(
        DatabaseSchema.syncMetadata,
        where: 'id = 1',
        limit: 1,
      )).single;
      final deviceId = metadata['device_id'] as String;
      final applied = <SyncEntity>[];
      final sortedRemote = [...remoteWinners]
        ..sort((a, b) => a.type.index.compareTo(b.type.index));
      for (final entity in sortedRemote) {
        final pendingRows = await tx.query(
          DatabaseSchema.syncOutbox,
          where: 'entity_type = ? AND entity_key = ?',
          whereArgs: [entity.type.storageValue, entity.id],
          limit: 1,
        );
        final currentLocal = await _entityAt(
          tx,
          entity.type,
          entity.id,
          deviceId,
        );
        final pending = pendingRows.firstOrNull;
        final localCandidate = pending?['operation'] == 'delete'
            ? SyncEntity(
                type: entity.type,
                id: entity.id,
                updatedAtUtc: DateTime.parse(
                  pending!['changed_at_utc'] as String,
                ).toUtc(),
                deletedAtUtc: DateTime.parse(
                  pending['changed_at_utc'] as String,
                ).toUtc(),
                sourceDeviceId: deviceId,
                payload: null,
                isDeleted: true,
              )
            : currentLocal;
        if (localCandidate != null && _compare(localCandidate, entity) >= 0) {
          continue;
        }
        await _applyRemote(tx, entity);
        await tx.delete(
          DatabaseSchema.syncOutbox,
          where: 'entity_type = ? AND entity_key = ?',
          whereArgs: [entity.type.storageValue, entity.id],
        );
        applied.add(entity);
      }
      for (final entity in localWinners) {
        final existing = await tx.query(
          DatabaseSchema.syncOutbox,
          where: 'entity_type = ? AND entity_key = ?',
          whereArgs: [entity.type.storageValue, entity.id],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;
        final current = await _entityAt(tx, entity.type, entity.id, deviceId);
        final operation = current == null || current.isDeleted
            ? 'delete'
            : 'upsert';
        final changedAt = current?.updatedAtUtc ?? nowUtc;
        await tx.insert(DatabaseSchema.syncOutbox, {
          'entity_type': entity.type.storageValue,
          'entity_key': entity.id,
          'operation': operation,
          'changed_at_utc': changedAt.toUtc().toIso8601String(),
          'attempt_count': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final linkFields = linkedUid == null
          ? null
          : <String, Object?>{'linked_uid': linkedUid};
      await tx.update(DatabaseSchema.syncMetadata, {
        ...?linkFields,
        if (markInitialSyncComplete) 'initial_sync_completed': 1,
        'last_error_code': null,
        'updated_at_utc': nowUtc.toUtc().toIso8601String(),
      }, where: 'id = 1');
      return applied;
    });
  }

  Future<void> removeOutbox(SyncOutboxOperation op) async {
    final db = await databaseService.open();
    await db.delete(
      DatabaseSchema.syncOutbox,
      where:
          'entity_type = ? AND entity_key = ? AND operation = ? AND changed_at_utc = ?',
      whereArgs: [
        op.type.storageValue,
        op.entityKey,
        op.operation == SyncOperation.delete ? 'delete' : 'upsert',
        op.changedAtUtc.toUtc().toIso8601String(),
      ],
    );
  }

  Future<void> updateOutboxFailure(SyncOutboxOperation op, String code) async {
    final db = await databaseService.open();
    await db.rawUpdate(
      '''UPDATE ${DatabaseSchema.syncOutbox}
      SET attempt_count = attempt_count + 1, last_error_code = ?
      WHERE entity_type = ? AND entity_key = ? AND operation = ? AND changed_at_utc = ?''',
      [
        code,
        op.type.storageValue,
        op.entityKey,
        op.operation == SyncOperation.delete ? 'delete' : 'upsert',
        op.changedAtUtc.toUtc().toIso8601String(),
      ],
    );
  }

  Future<void> setAttempt(DateTime nowUtc) => _updateMetadata({
    'last_attempt_at_utc': nowUtc.toUtc().toIso8601String(),
    'updated_at_utc': nowUtc.toUtc().toIso8601String(),
  });

  Future<void> markSuccess(DateTime nowUtc) => _updateMetadata({
    'last_successful_sync_at_utc': nowUtc.toUtc().toIso8601String(),
    'last_error_code': null,
    'updated_at_utc': nowUtc.toUtc().toIso8601String(),
  });

  Future<void> setError(String? code, DateTime nowUtc) => _updateMetadata({
    'last_error_code': code,
    'updated_at_utc': nowUtc.toUtc().toIso8601String(),
  });

  Future<void> _updateMetadata(Map<String, Object?> values) async {
    final db = await databaseService.open();
    await db.update(DatabaseSchema.syncMetadata, values, where: 'id = 1');
  }

  Future<Map<String, Object?>?> _one(
    DatabaseExecutor db,
    String table,
    String where,
    List<Object?> args,
  ) async {
    final rows = await db.query(table, where: where, whereArgs: args, limit: 1);
    return rows.firstOrNull;
  }

  Future<SyncEntity?> _entityAt(
    DatabaseExecutor executor,
    SyncEntityType type,
    String key,
    String deviceId,
  ) async {
    Map<String, Object?>? row;
    switch (type) {
      case SyncEntityType.routineDefinition:
        row = await _one(
          executor,
          DatabaseSchema.routineDefinitions,
          'id = ?',
          [Uri.decodeComponent(key)],
        );
        return row == null
            ? null
            : _entityMapper.routineDefinition(
                _definitionMapper.fromMap(row),
                deviceId,
              );
      case SyncEntityType.routineStepDefinition:
        final parts = FirestoreDocumentIds.splitPair(key);
        row = await _one(
          executor,
          DatabaseSchema.routineStepDefinitions,
          'routine_id = ? AND step_id = ?',
          [parts.$1, parts.$2],
        );
        return row == null
            ? null
            : _entityMapper.routineStepDefinition(
                _definitionMapper.stepFromMap(row),
                deviceId,
              );
      case SyncEntityType.routineRecord:
        final parts = FirestoreDocumentIds.splitPair(key);
        row = await _one(
          executor,
          DatabaseSchema.routineRecords,
          'date_key = ? AND routine_id = ?',
          [parts.$1, parts.$2],
        );
        return row == null
            ? null
            : _entityMapper.routineRecord(
                _recordMapper.fromData(RoutineRecordData.fromMap(row)),
                deviceId,
              );
      case SyncEntityType.routineStepRecord:
        final parts = FirestoreDocumentIds.splitTriple(key);
        row = await _one(
          executor,
          DatabaseSchema.routineStepRecords,
          'date_key = ? AND routine_id = ? AND step_id = ?',
          [parts.$1, parts.$2, parts.$3],
        );
        return row == null
            ? null
            : _entityMapper.routineStepRecord(
                _recordMapper.stepFromData(RoutineStepRecordData.fromMap(row)),
                deviceId,
              );
      case SyncEntityType.dailyReflection:
        row = await _one(
          executor,
          DatabaseSchema.dailyReflections,
          'date_key = ?',
          [key],
        );
        return row == null
            ? null
            : _entityMapper.dailyReflection(
                _reflectionMapper.fromData(row),
                deviceId,
              );
    }
  }

  int _compare(SyncEntity left, SyncEntity right) {
    final timestamp = left.updatedAtUtc.compareTo(right.updatedAtUtc);
    if (timestamp != 0) return timestamp;
    if (left.isDeleted != right.isDeleted) return left.isDeleted ? 1 : -1;
    return left.sourceDeviceId.compareTo(right.sourceDeviceId);
  }

  Future<void> _applyRemote(DatabaseExecutor tx, SyncEntity entity) async {
    final map = switch (entity.type) {
      SyncEntityType.routineDefinition => _definitionMapper.toMap(
        entity.payload as RoutineDefinition,
      ),
      SyncEntityType.routineStepDefinition => _definitionMapper.stepToMap(
        entity.payload as RoutineStepDefinition,
      ),
      SyncEntityType.routineRecord =>
        _recordMapper.toData(entity.payload as RoutineRecord).toMap(),
      SyncEntityType.routineStepRecord =>
        _recordMapper.stepToData(entity.payload as RoutineStepRecord).toMap(),
      SyncEntityType.dailyReflection => _reflectionRow(
        entity.payload as DailyReflection,
      ),
    };
    final table = switch (entity.type) {
      SyncEntityType.routineDefinition => DatabaseSchema.routineDefinitions,
      SyncEntityType.routineStepDefinition =>
        DatabaseSchema.routineStepDefinitions,
      SyncEntityType.routineRecord => DatabaseSchema.routineRecords,
      SyncEntityType.routineStepRecord => DatabaseSchema.routineStepRecords,
      SyncEntityType.dailyReflection => DatabaseSchema.dailyReflections,
    };
    final where = switch (entity.type) {
      SyncEntityType.routineDefinition => 'id = ?',
      SyncEntityType.routineStepDefinition => 'routine_id = ? AND step_id = ?',
      SyncEntityType.routineRecord => 'date_key = ? AND routine_id = ?',
      SyncEntityType.routineStepRecord =>
        'date_key = ? AND routine_id = ? AND step_id = ?',
      SyncEntityType.dailyReflection => 'date_key = ?',
    };
    final args = switch (entity.type) {
      SyncEntityType.routineDefinition => [Uri.decodeComponent(entity.id)],
      SyncEntityType.routineStepDefinition => _pairArgs(entity.id),
      SyncEntityType.routineRecord => _pairArgs(entity.id),
      SyncEntityType.routineStepRecord => _tripleArgs(entity.id),
      SyncEntityType.dailyReflection => [entity.id],
    };
    if (entity.isDeleted) {
      await tx.delete(table, where: where, whereArgs: args);
    } else {
      await tx.insert(table, map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Map<String, Object?> _reflectionRow(DailyReflection value) => {
    'date_key': value.day.toDateKey(),
    'rhythm': value.rhythm.name,
    'note': value.note,
    'recorded_at_utc': value.recordedAt.toUtc().toIso8601String(),
    'updated_at_utc': value.updatedAt.toUtc().toIso8601String(),
  };

  DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  List<String> _pairArgs(String id) {
    final parts = FirestoreDocumentIds.splitPair(id);
    return [parts.$1, parts.$2];
  }

  List<String> _tripleArgs(String id) {
    final parts = FirestoreDocumentIds.splitTriple(id);
    return [parts.$1, parts.$2, parts.$3];
  }

  String _newDeviceId() {
    final bytes = List<int>.generate(24, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
