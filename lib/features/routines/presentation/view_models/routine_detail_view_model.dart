import 'package:flutter/foundation.dart';

import '../../domain/models/routine.dart';
import '../../domain/models/routine_status.dart';
import '../../domain/models/routine_step.dart';

class RoutineDetailViewModel extends ChangeNotifier {
  RoutineDetailViewModel(this.routine) : _steps = List.of(routine.steps);

  final Routine routine;
  List<RoutineStep> _steps;
  List<RoutineStep>? _previousSteps;
  bool _notToday = false;
  bool _justCompleted = false;
  String? _notTodayReason;

  List<RoutineStep> get steps => List.unmodifiable(_steps);
  bool get isOptional => routine.isOptional;
  bool get hasUndo => _previousSteps != null;
  bool get justCompleted => _justCompleted;
  String? get notTodayReason => _notTodayReason;
  int get requiredCount => _steps.where((step) => step.isRequired).length;
  int get completedRequiredCount =>
      _steps.where((step) => step.isRequired && step.completed).length;
  bool get allRequiredCompleted =>
      requiredCount > 0 && completedRequiredCount == requiredCount;
  bool get hasRemainingSteps => _steps.any((step) => !step.completed);
  int get completedRakaat => _steps
      .where((step) => step.completed)
      .fold(0, (total, step) => total + (step.rakaatCount ?? 0));

  RoutineStatus get status {
    if (_notToday) return RoutineStatus.notToday;
    if (completedRequiredCount == 0) return RoutineStatus.pending;
    if (allRequiredCompleted) return RoutineStatus.completed;
    return RoutineStatus.partial;
  }

  bool toggleStep(String id) {
    final before = status;
    _previousSteps = _steps;
    _notToday = false;
    _notTodayReason = null;
    _steps = [
      for (final step in _steps)
        if (step.id == id) step.copyWith(completed: !step.completed) else step,
    ];
    notifyListeners();
    return before != RoutineStatus.completed &&
        status == RoutineStatus.completed;
  }

  bool completeOptionalStep(String id) {
    final index = _steps.indexWhere(
      (step) => step.id == id && !step.isRequired,
    );
    if (index == -1 || _steps[index].completed) return false;
    _previousSteps = _steps;
    _steps = [
      for (var stepIndex = 0; stepIndex < _steps.length; stepIndex++)
        if (stepIndex == index)
          _steps[stepIndex].copyWith(completed: true)
        else
          _steps[stepIndex],
    ];
    notifyListeners();
    return true;
  }

  void undoStep() {
    final previous = _previousSteps;
    if (previous == null) return;
    _steps = previous;
    _previousSteps = null;
    _notToday = false;
    _notTodayReason = null;
    notifyListeners();
  }

  bool markAllRemaining() {
    if (!hasRemainingSteps) return false;
    _previousSteps = _steps;
    _notToday = false;
    _notTodayReason = null;
    _justCompleted = true;
    _steps = [for (final step in _steps) step.copyWith(completed: true)];
    notifyListeners();
    return true;
  }

  bool markRequiredStepsDone() {
    if (allRequiredCompleted) return false;
    _previousSteps = _steps;
    _justCompleted = true;
    _steps = [
      for (final step in _steps)
        step.isRequired ? step.copyWith(completed: true) : step,
    ];
    notifyListeners();
    return true;
  }

  bool markNotToday({String? reason}) {
    if (!isOptional) return false;
    _notToday = true;
    _notTodayReason = reason;
    notifyListeners();
    return true;
  }
}
