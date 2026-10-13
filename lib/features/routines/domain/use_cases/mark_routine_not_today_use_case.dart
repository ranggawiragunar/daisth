import '../../../../core/time/domain/models/calendar_day.dart';
import '../models/routine.dart';
import '../repositories/routine_record_repository.dart';

class MarkRoutineNotTodayUseCase {
  const MarkRoutineNotTodayUseCase(this.repository);

  final RoutineRecordRepository repository;

  Future<void> call({
    required Routine routine,
    required CalendarDay day,
    required String? reason,
    DateTime? now,
  }) => repository.markNotToday(
    routine: routine,
    day: day,
    reason: reason,
    now: (now ?? DateTime.now()).toUtc(),
  );
}
