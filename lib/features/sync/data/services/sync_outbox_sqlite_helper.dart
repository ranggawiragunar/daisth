import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';

class SyncOutboxSqliteHelper {
  static final _localMutations = StreamController<void>.broadcast(sync: true);

  static Stream<void> get localMutations => _localMutations.stream;
  static void notifyLocalMutation() => _localMutations.add(null);

  static Future<void> enqueueLocalMutation(
    DatabaseExecutor transaction, {
    required String entityType,
    required String entityKey,
    required String operation,
    required DateTime changedAtUtc,
  }) async {
    await transaction.insert(DatabaseSchema.syncOutbox, {
      'entity_type': entityType,
      'entity_key': entityKey,
      'operation': operation,
      'changed_at_utc': changedAtUtc.toUtc().toIso8601String(),
      'attempt_count': 0,
      'last_error_code': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
