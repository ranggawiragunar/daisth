import '../../../../core/time/domain/models/calendar_day.dart';
import '../models/routine.dart';
import '../repositories/routine_record_repository.dart';

class SetRoutineStepCompletionUseCase {
  const SetRoutineStepCompletionUseCase({required this.repository});

  final RoutineRecordRepository repository;

  Future<void> call({
    required Routine routine,
    required CalendarDay day,
    required String stepId,
    required bool isCompleted,
    DateTime? now,
  }) => repository.setStepCompletion(
    routine: routine,
    day: day,
    stepId: stepId,
    isCompleted: isCompleted,
    now: (now ?? DateTime.now()).toUtc(),
  );
}
