import 'dart:math';

import '../../../../core/time/domain/models/calendar_day.dart';
import '../models/routine.dart';
import '../models/routine_definition.dart';
import '../models/routine_origin.dart';
import '../models/routine_requirement.dart';
import '../models/routine_step.dart';
import '../models/routine_status.dart';
import '../models/routine_step_definition.dart';
import '../repositories/routine_record_repository.dart';
import '../repositories/routine_repository.dart';
import 'resolve_routine_status_use_case.dart';

class RoutineDefinitionValidationException implements Exception {
  const RoutineDefinitionValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SaveCustomRoutineUseCase {
  const SaveCustomRoutineUseCase({
    required this.routines,
    required this.records,
  });
  final RoutineRepository routines;
  final RoutineRecordRepository records;
  final ResolveRoutineStatusUseCase _resolveStatus =
      const ResolveRoutineStatusUseCase();

  Future<void> call({
    required RoutineDefinition definition,
    required List<RoutineStepDefinition> steps,
    required DateTime now,
  }) async {
    final title = definition.title.trim();
    if (title.isEmpty) {
      throw const RoutineDefinitionValidationException(
        'Masukkan nama rutinitas.',
      );
    }
    if (title.length > 50) {
      throw const RoutineDefinitionValidationException(
        'Nama rutinitas maksimal 50 karakter.',
      );
    }
    final description = definition.description?.trim();
    if (description != null && description.length > 160) {
      throw const RoutineDefinitionValidationException(
        'Deskripsi maksimal 160 karakter.',
      );
    }
    if (steps.any((step) => step.title.trim().isEmpty)) {
      throw const RoutineDefinitionValidationException(
        'Isi atau hapus item checklist yang kosong.',
      );
    }
    if (steps.any((step) => step.title.trim().length > 80)) {
      throw const RoutineDefinitionValidationException(
        'Judul checklist maksimal 80 karakter.',
      );
    }
    if (steps.isNotEmpty && !steps.any((step) => step.isRequired)) {
      throw const RoutineDefinitionValidationException(
        'Pilih setidaknya satu langkah wajib.',
      );
    }
    if (definition.origin != RoutineOrigin.custom ||
        definition.templateKey != null) {
      throw const RoutineDefinitionValidationException(
        'Rutinitas bawaan tidak dapat diedit sebagai rutinitas khusus.',
      );
    }
    final existing = await routines.getRoutine(definition.id);
    if (existing?.origin != null && existing!.origin != RoutineOrigin.custom) {
      throw const RoutineDefinitionValidationException(
        'Rutinitas bawaan tidak dapat diganti.',
      );
    }
    final normalized = definition.copyWith(
      title: title,
      description: description,
      clearDescription: description == null || description.isEmpty,
      updatedAt: now.toUtc(),
    );
    await routines.saveRoutine(
      normalized,
      steps: [
        for (var index = 0; index < steps.length; index++)
          steps[index].copyWith(
            title: steps[index].title.trim(),
            sortOrder: index,
            updatedAt: now.toUtc(),
          ),
      ],
    );
    await recalculateTodayAfterDefinitionChange(normalized, steps, now);
  }

  Future<void> recalculateTodayAfterDefinitionChange(
    RoutineDefinition definition,
    List<RoutineStepDefinition> activeDefinitions,
    DateTime now,
  ) async {
    final day = CalendarDay.fromDateTime(now);
    final oldRecord = await records.getRoutineRecord(day, definition.id);
    if (oldRecord?.status == RoutineStatus.notToday) return;
    if (activeDefinitions.isEmpty && oldRecord == null) return;
    final routine = Routine(
      id: definition.id,
      title: definition.title,
      description: definition.description ?? '',
      preferredTime: '',
      contextLabel: '',
      isOptional: true,
      steps: [
        for (final step in activeDefinitions)
          RoutineStep(
            id: step.stepId,
            title: step.title,
            subtitle: '',
            requirement: step.isRequired
                ? RoutineRequirement.required
                : RoutineRequirement.optional,
          ),
      ],
    );
    final oldSteps = await records.getStepRecords(day, definition.id);
    final completed = {
      for (final step in oldSteps) step.stepId: step.isCompleted,
    };
    final status = activeDefinitions.isEmpty
        ? oldRecord?.status == RoutineStatus.completed
              ? RoutineStatus.completed
              : RoutineStatus.pending
        : _resolveStatus(
            routine: routine,
            completedStepIds: {
              for (final entry in completed.entries)
                if (entry.value) entry.key,
            },
          );
    await records.saveResolvedProgress(
      routine: routine,
      day: day,
      completedSteps: completed,
      status: status,
      notTodayReason: null,
      now: now.toUtc(),
    );
  }
}

String createCustomRoutineId({DateTime? now, Random? random}) {
  final time = (now ?? DateTime.now()).microsecondsSinceEpoch.toRadixString(16);
  final source = random ?? Random.secure();
  final suffix = List.generate(
    6,
    (_) => source.nextInt(256),
  ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return 'custom-$time-$suffix';
}

String createCustomRoutineStepId({DateTime? now, Random? random}) {
  final time = (now ?? DateTime.now()).microsecondsSinceEpoch.toRadixString(16);
  final source = random ?? Random.secure();
  final suffix = List.generate(
    6,
    (_) => source.nextInt(256),
  ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return 'step-$time-$suffix';
}
