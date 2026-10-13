import '../../../../core/time/domain/models/calendar_day.dart';
import '../../../routines/domain/models/routine.dart';
import '../../../routines/domain/models/routine_definition.dart';
import '../../../routines/domain/models/routine_record.dart';
import '../../../routines/domain/models/routine_step_definition.dart';
import '../../../routines/domain/models/routine_step_record.dart';
import '../../../routines/domain/models/routine_status.dart';
import '../../../routines/domain/repositories/routine_record_repository.dart';
import '../../../routines/domain/repositories/routine_repository.dart';
import '../models/history_day.dart';
import '../repositories/history_routine_resolver.dart';

class BuildHistoryDayUseCase {
  const BuildHistoryDayUseCase({
    required this.recordRepository,
    required this.routineRepository,
    required this.routineResolver,
  });

  final RoutineRecordRepository recordRepository;
  final RoutineRepository routineRepository;
  final HistoryRoutineResolver routineResolver;

  Future<HistoryDay> call(CalendarDay day) async {
    final recordBoundary = await recordRepository.getEarliestRecordDay();
    final definitionBoundary = await routineRepository
        .getEarliestRoutineCreationDay();
    final boundary = switch ((recordBoundary, definitionBoundary)) {
      (null, null) => null,
      (final value?, null) || (null, final value?) => value,
      (final record?, final definition?) =>
        record.compareTo(definition) <= 0 ? record : definition,
    };
    final today = CalendarDay.fromDateTime(DateTime.now());
    if (boundary == null ||
        day.compareTo(boundary) < 0 ||
        day.compareTo(today) >= 0) {
      return HistoryDay(
        day: day,
        entries: const [],
        summary: const HistorySummary(
          completed: 0,
          partial: 0,
          notToday: 0,
          unrecorded: 0,
        ),
      );
    }
    final records = await recordRepository.getRecordsForDay(day);
    final definitions = await routineRepository.getAllRoutineDefinitions();
    final steps = await routineRepository
        .getAllStepDefinitionsIncludingArchived();
    final stepRecords = await recordRepository.getStepRecordsForDay(day);
    return buildFromRecords(
      day,
      records,
      definitions: definitions,
      steps: steps,
      stepRecords: stepRecords,
    );
  }

  HistoryDay buildFromRecords(
    CalendarDay day,
    List<RoutineRecord> records, {
    required List<RoutineDefinition> definitions,
    required List<RoutineStepDefinition> steps,
    List<RoutineStepRecord> stepRecords = const [],
  }) {
    final definitionById = {for (final item in definitions) item.id: item};
    final stepDefinitionsByRoutine = <String, List<RoutineStepDefinition>>{};
    for (final step in steps) {
      stepDefinitionsByRoutine.putIfAbsent(step.routineId, () => []).add(step);
    }
    final recordsById = {for (final item in records) item.routineId: item};
    final stepRecordsByRoutine = <String, List<RoutineStepRecord>>{};
    for (final record in stepRecords) {
      stepRecordsByRoutine.putIfAbsent(record.routineId, () => []).add(record);
    }
    final ids = <String>{...recordsById.keys, ...mandatoryPrayerIds};
    final entries = <HistoryRoutineEntry>[];
    for (final id in ids) {
      final definition = definitionById[id];
      final routine = definition == null
          ? _fallbackRoutine(id, isMandatory: mandatoryPrayerIds.contains(id))
          : routineResolver.resolve(
                  definition,
                  stepDefinitionsByRoutine[id] ?? const [],
                ) ??
                _fallbackRoutine(
                  id,
                  isMandatory: mandatoryPrayerIds.contains(id),
                );
      final record = recordsById[id];
      final mandatory = mandatoryPrayerIds.contains(id);
      entries.add(
        HistoryRoutineEntry(
          routine: routine,
          status: record == null
              ? HistoryRoutineStatus.unrecorded
              : switch (record.status) {
                  RoutineStatus.completed => HistoryRoutineStatus.completed,
                  RoutineStatus.partial => HistoryRoutineStatus.partial,
                  RoutineStatus.notToday => HistoryRoutineStatus.notToday,
                  RoutineStatus.pending => HistoryRoutineStatus.unrecorded,
                },
          isMandatory: mandatory,
          isArchived: definition?.isArchived ?? false,
          sortOrder: mandatory
              ? mandatoryPrayerIds.indexOf(id)
              : (definition?.sortOrder ?? 9999),
          record: record,
          stepRecords: stepRecordsByRoutine[id] ?? const [],
        ),
      );
    }
    entries.sort((a, b) {
      final aMandatory = a.isMandatory ? 0 : 1;
      final bMandatory = b.isMandatory ? 0 : 1;
      final group = aMandatory.compareTo(bMandatory);
      if (group != 0) return group;
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0 ? order : a.routine.title.compareTo(b.routine.title);
    });
    return HistoryDay(
      day: day,
      entries: List.unmodifiable(entries),
      summary: HistorySummary.fromEntries(entries),
    );
  }

  Routine _fallbackRoutine(String id, {required bool isMandatory}) => Routine(
    id: id,
    title: switch (id) {
      'subuh' => 'Sholat Subuh',
      'zuhur' => 'Sholat Zuhur',
      'asar' => 'Sholat Asar',
      'maghrib' => 'Sholat Maghrib',
      'isya' => 'Sholat Isya',
      _ => 'Routine',
    },
    description: '',
    preferredTime: '',
    contextLabel: '',
    isOptional: !isMandatory,
    steps: const [],
  );
}
