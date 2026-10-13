import '../../../../core/time/domain/models/calendar_day.dart';

class RoutineReminderState {
  const RoutineReminderState({
    required this.calendarDay,
    required this.routineId,
    required this.followUpSuppressed,
    required this.updatedAt,
    this.snoozedUntil,
    this.followUpScheduledAt,
    this.lastAction,
    this.lastActionAt,
  });

  final CalendarDay calendarDay;
  final String routineId;
  final DateTime? snoozedUntil;
  final DateTime? followUpScheduledAt;
  final bool followUpSuppressed;
  final String? lastAction;
  final DateTime? lastActionAt;
  final DateTime updatedAt;
}
