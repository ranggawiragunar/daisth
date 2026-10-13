import '../../../../core/time/domain/models/calendar_day.dart';
import '../models/routine_reminder_state.dart';

abstract interface class RoutineReminderStateRepository {
  Future<RoutineReminderState?> getState(CalendarDay day, String routineId);
  Future<List<RoutineReminderState>> getStatesForDay(CalendarDay day);
  Future<void> save(RoutineReminderState state);
  Future<void> recordSnooze({
    required CalendarDay day,
    required String routineId,
    required DateTime snoozedUntil,
    required DateTime now,
  });
  Future<void> recordFollowUpScheduled({
    required CalendarDay day,
    required String routineId,
    required DateTime scheduledAt,
    required DateTime now,
  });
  Future<void> suppressFollowUp({
    required CalendarDay day,
    required String routineId,
    required DateTime now,
  });
  Future<void> recordAction({
    required CalendarDay day,
    required String routineId,
    required String action,
    required DateTime now,
  });
  Future<void> clearSnooze(
    CalendarDay day,
    String routineId, {
    required DateTime now,
  });
  Future<void> clearFollowUp(
    CalendarDay day,
    String routineId, {
    required DateTime now,
  });
  Future<void> clearState(CalendarDay day, String routineId);
}
