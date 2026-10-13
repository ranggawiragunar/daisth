import '../../../../core/time/domain/models/calendar_day.dart';
import '../models/routine.dart';
import '../models/routine_record.dart';
import '../models/routine_status.dart';
import '../models/routine_step_record.dart';

class RoutineRecordChange {
  const RoutineRecordChange(this.calendarDay, this.routineId);

  final CalendarDay calendarDay;
  final String routineId;
}

abstract interface class RoutineRecordRepository {
  Stream<RoutineRecordChange> get changes;

  Future<RoutineRecord?> getRoutineRecord(CalendarDay day, String routineId);

  Future<List<RoutineStepRecord>> getStepRecords(
    CalendarDay day,
    String routineId,
  );

  Future<List<RoutineRecord>> getRecordsForDay(CalendarDay day);

  Future<void> setStepCompletion({
    required Routine routine,
    required CalendarDay day,
    required String stepId,
    required bool isCompleted,
    required DateTime now,
  });

  Future<void> markCompleted({
    required Routine routine,
    required CalendarDay day,
    required DateTime now,
  });

  Future<void> markNotToday({
    required Routine routine,
    required CalendarDay day,
    required String? reason,
    required DateTime now,
  });

  Future<void> clearRoutineRecord(CalendarDay day, String routineId);

  Future<void> saveResolvedProgress({
    required Routine routine,
    required CalendarDay day,
    required Map<String, bool> completedSteps,
    required RoutineStatus status,
    required String? notTodayReason,
    required DateTime now,
  });
}
