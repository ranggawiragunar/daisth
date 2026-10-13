import '../../../../core/time/domain/models/calendar_day.dart';
import '../../../routines/domain/models/routine.dart';
import '../../../routines/domain/models/routine_record.dart';
import '../../../routines/domain/models/routine_step_record.dart';

const mandatoryPrayerIds = ['subuh', 'zuhur', 'asar', 'maghrib', 'isya'];

enum HistoryRoutineStatus { completed, partial, notToday, unrecorded }

class HistoryRoutineEntry {
  const HistoryRoutineEntry({
    required this.routine,
    required this.status,
    required this.isMandatory,
    required this.isArchived,
    required this.sortOrder,
    this.record,
    this.stepRecords = const [],
  });

  final Routine routine;
  final HistoryRoutineStatus status;
  final bool isMandatory;
  final bool isArchived;
  final int sortOrder;
  final RoutineRecord? record;
  final List<RoutineStepRecord> stepRecords;
}

class HistorySummary {
  const HistorySummary({
    required this.completed,
    required this.partial,
    required this.notToday,
    required this.unrecorded,
  });

  final int completed;
  final int partial;
  final int notToday;
  final int unrecorded;

  factory HistorySummary.fromEntries(List<HistoryRoutineEntry> entries) =>
      HistorySummary(
        completed: entries
            .where((e) => e.status == HistoryRoutineStatus.completed)
            .length,
        partial: entries
            .where((e) => e.status == HistoryRoutineStatus.partial)
            .length,
        notToday: entries
            .where((e) => e.status == HistoryRoutineStatus.notToday)
            .length,
        unrecorded: entries
            .where((e) => e.status == HistoryRoutineStatus.unrecorded)
            .length,
      );

  bool get isEmpty => completed + partial + notToday + unrecorded == 0;
}

class HistoryDay {
  const HistoryDay({
    required this.day,
    required this.entries,
    required this.summary,
  });

  final CalendarDay day;
  final List<HistoryRoutineEntry> entries;
  final HistorySummary summary;
}
