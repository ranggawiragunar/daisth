import 'package:flutter/foundation.dart';

import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/models/routine.dart';
import '../../domain/models/routine_record.dart';
import '../../domain/models/routine_status.dart';
import '../../domain/models/routine_step.dart';
import '../../domain/repositories/routine_record_repository.dart';
import '../../domain/use_cases/mark_routine_complete_use_case.dart';
import '../../domain/use_cases/mark_routine_not_today_use_case.dart';
import '../../domain/use_cases/resolve_routine_status_use_case.dart';
import '../../domain/use_cases/set_routine_step_completion_use_case.dart';

class RoutineDetailViewModel extends ChangeNotifier {
  RoutineDetailViewModel({
    required this.routine,
    required this.repository,
    required this.setStepCompletion,
    required this.markRoutineComplete,
    required this.markRoutineNotToday,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       calendarDay = CalendarDay.fromDateTime((clock ?? DateTime.now)());

  final Routine routine;
  final RoutineRecordRepository repository;
  final SetRoutineStepCompletionUseCase setStepCompletion;
  final MarkRoutineCompleteUseCase markRoutineComplete;
  final MarkRoutineNotTodayUseCase markRoutineNotToday;
  final DateTime Function() _now;
  final CalendarDay calendarDay;
  final ResolveRoutineStatusUseCase _resolveStatus =
      const ResolveRoutineStatusUseCase();

  final Map<String, bool> _completed = {};
  Map<String, bool>? _previousSteps;
  RoutineRecord? _record;
  bool isLoading = true;
  bool isSaving = false;
  bool justCompleted = false;
  String? errorMessage;
  String? _notTodayReason;
  bool _disposed = false;

  List<RoutineStep> get steps => List.unmodifiable([
    for (final step in routine.steps)
      step.copyWith(completed: _completed[step.id] ?? false),
  ]);
  bool get isOptional => routine.isOptional;
  bool get hasUndo => _previousSteps != null;
  String? get notTodayReason => _notTodayReason;
  int get requiredCount =>
      routine.steps.where((step) => step.isRequired).length;
  int get completedRequiredCount => routine.steps
      .where((step) => step.isRequired && (_completed[step.id] ?? false))
      .length;
  bool get allRequiredCompleted =>
      requiredCount > 0 && completedRequiredCount == requiredCount;
  bool get hasRemainingSteps =>
      routine.steps.any((step) => !(_completed[step.id] ?? false));
  int get completedRakaat => routine.steps
      .where((step) => _completed[step.id] ?? false)
      .fold(0, (total, step) => total + (step.rakaatCount ?? 0));

  RoutineStatus get status =>
      _record?.status ??
      _resolveStatus(
        routine: routine,
        completedStepIds: {
          for (final entry in _completed.entries)
            if (entry.value) entry.key,
        },
      );

  Future<void> initialize() async {
    isLoading = true;
    _notifyIfAlive();
    try {
      await _loadFromRepository();
    } catch (_) {
      errorMessage = 'Progress routine belum dapat dimuat.';
    } finally {
      isLoading = false;
      _notifyIfAlive();
    }
  }

  Future<bool> toggleStep(String id) async {
    final step = routine.steps.where((item) => item.id == id).firstOrNull;
    if (step == null || isSaving || isLoading) return false;
    final next = !(_completed[id] ?? false);
    final before = status;
    return _mutate(() async {
      _previousSteps = Map.of(_completed);
      await setStepCompletion(
        routine: routine,
        day: calendarDay,
        stepId: id,
        isCompleted: next,
        now: _now(),
      );
      await _loadFromRepository();
      if (before != RoutineStatus.completed &&
          status == RoutineStatus.completed) {
        justCompleted = true;
      } else if (status != RoutineStatus.completed) {
        justCompleted = false;
      }
      return justCompleted;
    });
  }

  Future<bool> completeOptionalStep(String id) async {
    final step = routine.steps.where((item) => item.id == id).firstOrNull;
    if (step == null || step.isRequired || _completed[id] == true) return false;
    return toggleStep(id);
  }

  Future<void> undoStep() async {
    final previous = _previousSteps;
    if (previous == null || isSaving || isLoading) return;
    _previousSteps = null;
    await _mutate(() async {
      await _saveProgress(previous, manageLoading: false);
      return false;
    });
  }

  Future<bool> markAllRemaining() async {
    if (!hasRemainingSteps || isSaving || isLoading) return false;
    final before = status;
    return _mutate(() async {
      _previousSteps = Map.of(_completed);
      await markRoutineComplete(
        routine: routine,
        day: calendarDay,
        now: _now(),
      );
      await _loadFromRepository();
      justCompleted = before != RoutineStatus.completed;
      return justCompleted;
    });
  }

  Future<bool> markRequiredStepsDone() async {
    if (allRequiredCompleted || isSaving || isLoading) return false;
    final completed = Map<String, bool>.of(_completed);
    for (final step in routine.steps.where((step) => step.isRequired)) {
      completed[step.id] = true;
    }
    final before = status;
    return _mutate(() async {
      _previousSteps = Map.of(_completed);
      await _saveProgress(completed, manageLoading: false);
      justCompleted = before != RoutineStatus.completed;
      return justCompleted;
    });
  }

  Future<bool> markNotToday({String? reason}) async {
    if (!isOptional ||
        status == RoutineStatus.notToday ||
        isSaving ||
        isLoading) {
      return false;
    }
    return _mutate(() async {
      await markRoutineNotToday(
        routine: routine,
        day: calendarDay,
        reason: reason,
        now: _now(),
      );
      await _loadFromRepository();
      return true;
    });
  }

  Future<void> _saveProgress(
    Map<String, bool> completed, {
    bool manageLoading = true,
  }) async {
    final status = _resolveStatus(
      routine: routine,
      completedStepIds: {
        for (final entry in completed.entries)
          if (entry.value) entry.key,
      },
    );
    if (manageLoading) isSaving = true;
    _notifyIfAlive();
    try {
      await repository.saveResolvedProgress(
        routine: routine,
        day: calendarDay,
        completedSteps: completed,
        status: status,
        notTodayReason: null,
        now: _now().toUtc(),
      );
      await _loadFromRepository();
      justCompleted = status == RoutineStatus.completed;
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Progress routine belum dapat disimpan. Coba lagi.';
      rethrow;
    } finally {
      if (manageLoading) isSaving = false;
      _notifyIfAlive();
    }
  }

  Future<bool> _mutate(Future<bool> Function() action) async {
    isSaving = true;
    errorMessage = null;
    _notifyIfAlive();
    try {
      final result = await action();
      return result;
    } catch (_) {
      errorMessage = 'Progress routine belum dapat disimpan. Coba lagi.';
      return false;
    } finally {
      isSaving = false;
      _notifyIfAlive();
    }
  }

  Future<void> _loadFromRepository() async {
    final record = await repository.getRoutineRecord(calendarDay, routine.id);
    final stepRecords = await repository.getStepRecords(
      calendarDay,
      routine.id,
    );
    _record = record;
    _completed
      ..clear()
      ..addEntries(
        stepRecords.map((step) => MapEntry(step.stepId, step.isCompleted)),
      );
    _notTodayReason = record?.notTodayReason;
  }

  void _notifyIfAlive() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
