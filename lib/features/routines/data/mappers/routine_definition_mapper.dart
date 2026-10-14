import '../../domain/models/prayer_key.dart';
import '../../domain/models/routine_definition.dart';
import '../../domain/models/routine_origin.dart';
import '../../domain/models/routine_priority.dart';
import '../../domain/models/routine_schedule.dart';
import '../../domain/models/routine_step_definition.dart';

class RoutineDefinitionMapper {
  const RoutineDefinitionMapper();

  RoutineDefinition fromMap(Map<String, Object?> row) {
    final kind = row['schedule_kind'] as String;
    final schedule = switch (kind) {
      'fixed' => RoutineSchedule.fixed(row['fixed_time_minutes'] as int),
      'prayer' => RoutineSchedule.prayer(
        PrayerKey.fromStorage(row['prayer_key'] as String) ??
            (throw FormatException('Unknown prayer key: ${row['prayer_key']}')),
      ),
      _ => throw FormatException('Unknown schedule kind: $kind'),
    };
    return RoutineDefinition(
      id: row['id'] as String,
      origin:
          RoutineOrigin.fromStorage(row['origin'] as String) ??
          (throw FormatException('Unknown routine origin: ${row['origin']}')),
      templateKey: row['template_key'] as String?,
      title: row['title'] as String,
      description: row['description'] as String?,
      isEnabled: row['is_enabled'] == 1,
      isArchived: row['is_archived'] == 1,
      schedule: schedule,
      reminderEnabled: row['reminder_enabled'] == 1,
      priority:
          RoutinePriority.fromStorage(row['priority'] as String) ??
          (throw FormatException('Unknown priority: ${row['priority']}')),
      sortOrder: row['sort_order'] as int,
      createdAt: DateTime.parse(row['created_at_utc'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at_utc'] as String).toUtc(),
    );
  }

  Map<String, Object?> toMap(RoutineDefinition definition) {
    final schedule = definition.schedule;
    return {
      'id': definition.id,
      'origin': definition.origin.storageValue,
      'template_key': definition.templateKey,
      'title': definition.title,
      'description': definition.description,
      'is_enabled': definition.isEnabled ? 1 : 0,
      'is_archived': definition.isArchived ? 1 : 0,
      'schedule_kind': schedule.kind,
      'fixed_time_minutes': schedule.minutesAfterMidnight,
      'prayer_key': schedule.prayerKey?.storageValue,
      'reminder_enabled': definition.reminderEnabled ? 1 : 0,
      'priority': definition.priority.storageValue,
      'sort_order': definition.sortOrder,
      'created_at_utc': definition.createdAt.toUtc().toIso8601String(),
      'updated_at_utc': definition.updatedAt.toUtc().toIso8601String(),
    };
  }

  RoutineStepDefinition stepFromMap(Map<String, Object?> row) =>
      RoutineStepDefinition(
        routineId: row['routine_id'] as String,
        stepId: row['step_id'] as String,
        title: row['title'] as String,
        isRequired: row['is_required'] == 1,
        isArchived: row['is_archived'] == 1,
        sortOrder: row['sort_order'] as int,
        createdAt: DateTime.parse(row['created_at_utc'] as String).toUtc(),
        updatedAt: DateTime.parse(row['updated_at_utc'] as String).toUtc(),
      );

  Map<String, Object?> stepToMap(RoutineStepDefinition step) => {
    'routine_id': step.routineId,
    'step_id': step.stepId,
    'title': step.title,
    'is_required': step.isRequired ? 1 : 0,
    'is_archived': step.isArchived ? 1 : 0,
    'sort_order': step.sortOrder,
    'created_at_utc': step.createdAt.toUtc().toIso8601String(),
    'updated_at_utc': step.updatedAt.toUtc().toIso8601String(),
  };
}
