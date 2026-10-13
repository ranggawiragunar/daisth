import '../../../../core/time/domain/models/calendar_day.dart';
import '../../../routines/domain/repositories/routine_record_repository.dart';
import '../../../routines/domain/repositories/routine_repository.dart';
import '../models/history_day.dart';
import '../models/history_page.dart';
import 'build_history_day_use_case.dart';

class GetHistoryRangeUseCase {
  const GetHistoryRangeUseCase({
    required this.recordRepository,
    required this.routineRepository,
    required this.buildDay,
  });

  static const pageSize = 30;
  final RoutineRecordRepository recordRepository;
  final RoutineRepository routineRepository;
  final BuildHistoryDayUseCase buildDay;

  Future<CalendarDay?> get earliestDay async {
    final recordDay = await recordRepository.getEarliestRecordDay();
    final definitionDay = await routineRepository
        .getEarliestRoutineCreationDay();
    if (recordDay == null) return definitionDay;
    if (definitionDay == null) return recordDay;
    return recordDay.compareTo(definitionDay) <= 0 ? recordDay : definitionDay;
  }

  Future<HistoryPage> initial({DateTime? now}) async {
    final yesterday = CalendarDay.fromDateTime(
      (now ?? DateTime.now()).toLocal(),
    ).addDays(-1);
    final earliest = await earliestDay;
    if (earliest == null || earliest.compareTo(yesterday) > 0) {
      return const HistoryPage(days: [], earliestDay: null, hasEarlier: false);
    }
    return loadBefore(yesterday.addDays(1), now: now, includeEnd: true);
  }

  Future<HistoryPage> loadBefore(
    CalendarDay endExclusive, {
    DateTime? now,
    bool includeEnd = false,
  }) async {
    final earliest = await earliestDay;
    if (earliest == null) {
      return const HistoryPage(days: [], earliestDay: null, hasEarlier: false);
    }
    var end = includeEnd ? endExclusive : endExclusive.addDays(-1);
    final yesterday = CalendarDay.fromDateTime(
      (now ?? DateTime.now()).toLocal(),
    ).addDays(-1);
    if (end.compareTo(yesterday) > 0) end = yesterday;
    if (end.compareTo(earliest) < 0) {
      return HistoryPage(
        days: const [],
        earliestDay: earliest.toDateKey(),
        hasEarlier: false,
      );
    }
    final startCandidate = end.addDays(-(pageSize - 1));
    final start = startCandidate.compareTo(earliest) < 0
        ? earliest
        : startCandidate;
    final records = await recordRepository.getRecordsBetween(start, end);
    final stepRecords = await recordRepository.getStepRecordsBetween(
      start,
      end,
    );
    final definitions = await routineRepository.getAllRoutineDefinitions();
    final steps = await routineRepository
        .getAllStepDefinitionsIncludingArchived();
    final recordsByDay = _group(records, (record) => record.calendarDay);
    final stepsByDay = _group(stepRecords, (record) => record.calendarDay);
    final count = end.toDateTime().difference(start.toDateTime()).inDays;
    final days = <HistoryDay>[];
    for (var offset = 0; offset <= count; offset++) {
      final day = end.addDays(-offset);
      days.add(
        buildDay.buildFromRecords(
          day,
          recordsByDay[day.toDateKey()] ?? const [],
          definitions: definitions,
          steps: steps,
          stepRecords: stepsByDay[day.toDateKey()] ?? const [],
        ),
      );
    }
    return HistoryPage(
      days: List.unmodifiable(days),
      earliestDay: earliest.toDateKey(),
      hasEarlier: start.compareTo(earliest) > 0,
    );
  }

  Map<String, List<T>> _group<T>(List<T> items, CalendarDay Function(T) dayOf) {
    final groups = <String, List<T>>{};
    for (final item in items) {
      groups.putIfAbsent(dayOf(item).toDateKey(), () => []).add(item);
    }
    return groups;
  }
}
