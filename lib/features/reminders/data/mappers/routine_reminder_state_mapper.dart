import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/models/routine_reminder_state.dart';

class RoutineReminderStateMapper {
  RoutineReminderState fromMap(Map<String, Object?> row) =>
      RoutineReminderState(
        calendarDay: _day(row['date_key'] as String),
        routineId: row['routine_id'] as String,
        snoozedUntil: _date(row['snoozed_until_utc'] as String?),
        followUpScheduledAt: _date(
          row['follow_up_scheduled_at_utc'] as String?,
        ),
        followUpSuppressed: row['follow_up_suppressed'] == 1,
        lastAction: row['last_action'] as String?,
        lastActionAt: _date(row['last_action_at_utc'] as String?),
        updatedAt: DateTime.parse(row['updated_at_utc'] as String),
      );

  Map<String, Object?> toMap(RoutineReminderState state) => {
    'date_key': state.calendarDay.toDateKey(),
    'routine_id': state.routineId,
    'snoozed_until_utc': state.snoozedUntil?.toUtc().toIso8601String(),
    'follow_up_scheduled_at_utc': state.followUpScheduledAt
        ?.toUtc()
        .toIso8601String(),
    'follow_up_suppressed': state.followUpSuppressed ? 1 : 0,
    'last_action': state.lastAction,
    'last_action_at_utc': state.lastActionAt?.toUtc().toIso8601String(),
    'updated_at_utc': state.updatedAt.toUtc().toIso8601String(),
  };

  CalendarDay _day(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return CalendarDay(year: parts[0], month: parts[1], day: parts[2]);
  }

  DateTime? _date(String? value) =>
      value == null ? null : DateTime.parse(value).toUtc();
}
