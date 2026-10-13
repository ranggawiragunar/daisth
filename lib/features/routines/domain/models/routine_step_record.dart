import '../../../../core/time/domain/models/calendar_day.dart';

class RoutineStepRecord {
  const RoutineStepRecord({
    required this.calendarDay,
    required this.routineId,
    required this.stepId,
    required this.isCompleted,
    required this.recordedAt,
    required this.updatedAt,
    this.completedAt,
  });

  final CalendarDay calendarDay;
  final String routineId;
  final String stepId;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime recordedAt;
  final DateTime updatedAt;
}
