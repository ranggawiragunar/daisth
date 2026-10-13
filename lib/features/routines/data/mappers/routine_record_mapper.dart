import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/models/routine_record.dart';
import '../../domain/models/routine_status.dart';
import '../../domain/models/routine_step_record.dart';
import '../models/routine_record_data.dart';
import '../models/routine_step_record_data.dart';

class RoutineRecordMapper {
  RoutineRecord fromData(RoutineRecordData data) => RoutineRecord(
    calendarDay: _day(data.dateKey),
    routineId: data.routineId,
    status: _status(data.status),
    completedAt: _utc(data.completedAtUtc),
    recordedAt: _utc(data.recordedAtUtc)!,
    updatedAt: _utc(data.updatedAtUtc)!,
    notTodayReason: data.notTodayReason,
  );

  RoutineStepRecord stepFromData(RoutineStepRecordData data) =>
      RoutineStepRecord(
        calendarDay: _day(data.dateKey),
        routineId: data.routineId,
        stepId: data.stepId,
        isCompleted: data.isCompleted,
        completedAt: _utc(data.completedAtUtc),
        recordedAt: _utc(data.recordedAtUtc)!,
        updatedAt: _utc(data.updatedAtUtc)!,
      );

  RoutineRecordData toData(RoutineRecord record) => RoutineRecordData(
    dateKey: record.calendarDay.toDateKey(),
    routineId: record.routineId,
    status: record.status.name,
    completedAtUtc: _iso(record.completedAt),
    recordedAtUtc: record.recordedAt.toUtc().toIso8601String(),
    updatedAtUtc: record.updatedAt.toUtc().toIso8601String(),
    notTodayReason: record.notTodayReason,
  );

  RoutineStepRecordData stepToData(RoutineStepRecord record) =>
      RoutineStepRecordData(
        dateKey: record.calendarDay.toDateKey(),
        routineId: record.routineId,
        stepId: record.stepId,
        isCompleted: record.isCompleted,
        completedAtUtc: _iso(record.completedAt),
        recordedAtUtc: record.recordedAt.toUtc().toIso8601String(),
        updatedAtUtc: record.updatedAt.toUtc().toIso8601String(),
      );

  CalendarDay _day(String dateKey) {
    final parts = dateKey.split('-').map(int.parse).toList();
    return CalendarDay(year: parts[0], month: parts[1], day: parts[2]);
  }

  DateTime? _utc(String? value) =>
      value == null ? null : DateTime.parse(value).toUtc();

  String? _iso(DateTime? value) => value?.toUtc().toIso8601String();

  RoutineStatus _status(String value) => switch (value) {
    'partial' => RoutineStatus.partial,
    'completed' => RoutineStatus.completed,
    'notToday' => RoutineStatus.notToday,
    _ => throw FormatException('Unknown persisted routine status: $value'),
  };
}
