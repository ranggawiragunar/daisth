import '../../../../core/time/domain/models/calendar_day.dart';
import 'routine_status.dart';

class RoutineRecord {
  const RoutineRecord({
    required this.calendarDay,
    required this.routineId,
    required this.status,
    required this.recordedAt,
    required this.updatedAt,
    this.completedAt,
    this.notTodayReason,
  });

  final CalendarDay calendarDay;
  final String routineId;
  final RoutineStatus status;
  final DateTime? completedAt;
  final DateTime recordedAt;
  final DateTime updatedAt;
  final String? notTodayReason;
}
