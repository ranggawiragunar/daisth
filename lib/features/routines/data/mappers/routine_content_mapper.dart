import '../../domain/models/routine_content.dart';

class RoutineContentMapper {
  const RoutineContentMapper();

  RoutineContent fromMap(Map<String, Object?> row) => RoutineContent(
    routineId: row['routine_id'] as String,
    serializedDelta: row['delta_json'] as String,
    plainText: row['plain_text'] as String,
    formatVersion: row['format_version'] as int,
    createdAt: DateTime.parse(row['created_at_utc'] as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at_utc'] as String).toUtc(),
  );

  Map<String, Object?> toMap(RoutineContent value) => {
    'routine_id': value.routineId,
    'delta_json': value.serializedDelta,
    'plain_text': value.plainText,
    'format_version': value.formatVersion,
    'created_at_utc': value.createdAt.toUtc().toIso8601String(),
    'updated_at_utc': value.updatedAt.toUtc().toIso8601String(),
  };
}
