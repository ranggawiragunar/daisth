import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/models/routine_reminder_state.dart';
import '../../domain/repositories/routine_reminder_state_repository.dart';
import '../mappers/routine_reminder_state_mapper.dart';
import '../services/routine_reminder_state_sqlite_service.dart';

class RoutineReminderStateRepositoryData
    implements RoutineReminderStateRepository {
  RoutineReminderStateRepositoryData({
    required this.service,
    required this.mapper,
  });
  final RoutineReminderStateSqliteService service;
  final RoutineReminderStateMapper mapper;

  @override
  Future<RoutineReminderState?> getState(
    CalendarDay day,
    String routineId,
  ) async {
    final row = await service.get(day.toDateKey(), routineId);
    return row == null ? null : mapper.fromMap(row);
  }

  @override
  Future<List<RoutineReminderState>> getStatesForDay(CalendarDay day) async =>
      (await service.getForDay(
        day.toDateKey(),
      )).map(mapper.fromMap).toList(growable: false);
  @override
  Future<void> save(RoutineReminderState state) =>
      service.upsert(mapper.toMap(state));

  Future<RoutineReminderState> _update(
    CalendarDay day,
    String routineId,
    DateTime now,
    RoutineReminderState Function(RoutineReminderState old) change,
  ) async {
    final old =
        await getState(day, routineId) ??
        RoutineReminderState(
          calendarDay: day,
          routineId: routineId,
          followUpSuppressed: false,
          updatedAt: now.toUtc(),
        );
    final next = change(old);
    await save(next);
    return next;
  }

  @override
  Future<void> recordSnooze({
    required CalendarDay day,
    required String routineId,
    required DateTime snoozedUntil,
    required DateTime now,
  }) async => _update(
    day,
    routineId,
    now,
    (s) => RoutineReminderState(
      calendarDay: day,
      routineId: routineId,
      snoozedUntil: snoozedUntil.toUtc(),
      followUpScheduledAt: s.followUpScheduledAt,
      followUpSuppressed: true,
      lastAction: 'snooze',
      lastActionAt: now.toUtc(),
      updatedAt: now.toUtc(),
    ),
  );
  @override
  Future<void> recordFollowUpScheduled({
    required CalendarDay day,
    required String routineId,
    required DateTime scheduledAt,
    required DateTime now,
  }) async => _update(
    day,
    routineId,
    now,
    (s) => RoutineReminderState(
      calendarDay: day,
      routineId: routineId,
      snoozedUntil: s.snoozedUntil,
      followUpScheduledAt: scheduledAt.toUtc(),
      followUpSuppressed: s.followUpSuppressed,
      lastAction: s.lastAction,
      lastActionAt: s.lastActionAt,
      updatedAt: now.toUtc(),
    ),
  );
  @override
  Future<void> suppressFollowUp({
    required CalendarDay day,
    required String routineId,
    required DateTime now,
  }) async => _update(
    day,
    routineId,
    now,
    (s) => RoutineReminderState(
      calendarDay: day,
      routineId: routineId,
      snoozedUntil: s.snoozedUntil,
      followUpScheduledAt: s.followUpScheduledAt,
      followUpSuppressed: true,
      lastAction: s.lastAction,
      lastActionAt: s.lastActionAt,
      updatedAt: now.toUtc(),
    ),
  );
  @override
  Future<void> recordAction({
    required CalendarDay day,
    required String routineId,
    required String action,
    required DateTime now,
  }) async => _update(
    day,
    routineId,
    now,
    (s) => RoutineReminderState(
      calendarDay: day,
      routineId: routineId,
      snoozedUntil: s.snoozedUntil,
      followUpScheduledAt: s.followUpScheduledAt,
      followUpSuppressed: s.followUpSuppressed,
      lastAction: action,
      lastActionAt: now.toUtc(),
      updatedAt: now.toUtc(),
    ),
  );
  @override
  Future<void> clearSnooze(
    CalendarDay day,
    String routineId, {
    required DateTime now,
  }) async => _update(
    day,
    routineId,
    now,
    (s) => RoutineReminderState(
      calendarDay: day,
      routineId: routineId,
      followUpScheduledAt: s.followUpScheduledAt,
      followUpSuppressed: s.followUpSuppressed,
      lastAction: s.lastAction,
      lastActionAt: s.lastActionAt,
      updatedAt: now.toUtc(),
    ),
  );
  @override
  Future<void> clearFollowUp(
    CalendarDay day,
    String routineId, {
    required DateTime now,
  }) async => _update(
    day,
    routineId,
    now,
    (s) => RoutineReminderState(
      calendarDay: day,
      routineId: routineId,
      snoozedUntil: s.snoozedUntil,
      followUpSuppressed: s.followUpSuppressed,
      lastAction: s.lastAction,
      lastActionAt: s.lastActionAt,
      updatedAt: now.toUtc(),
    ),
  );
  @override
  Future<void> clearState(CalendarDay day, String routineId) =>
      service.delete(day.toDateKey(), routineId);
}
