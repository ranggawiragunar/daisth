import '../../../../core/time/domain/models/calendar_day.dart';
import '../models/routine.dart';
import '../models/routine_status.dart';
import '../repositories/routine_record_repository.dart';
import 'resolve_routine_status_use_case.dart';

class MarkRoutineCompleteUseCase {
  const MarkRoutineCompleteUseCase({
    required this.repository,
    required this.resolveStatus,
  });

  final RoutineRecordRepository repository;
  final ResolveRoutineStatusUseCase resolveStatus;

  Future<void> call({
    required Routine routine,
    required CalendarDay day,
    DateTime? now,
  }) async {
    final completed = {for (final step in routine.steps) step.id: true};
    final status = resolveStatus(
      routine: routine,
      completedStepIds: completed.keys.toSet(),
    );
    if (status != RoutineStatus.completed) {
      throw StateError('Routine requirements are not complete.');
    }
    await repository.saveResolvedProgress(
      routine: routine,
      day: day,
      completedSteps: completed,
      status: status,
      notTodayReason: null,
      now: (now ?? DateTime.now()).toUtc(),
    );
  }
}
