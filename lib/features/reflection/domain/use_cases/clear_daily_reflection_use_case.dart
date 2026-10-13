import '../../../../core/time/domain/models/calendar_day.dart';
import '../repositories/reflection_repository.dart';

class ClearDailyReflectionUseCase {
  const ClearDailyReflectionUseCase(this.repository);

  final ReflectionRepository repository;

  Future<bool> call(CalendarDay day) => repository.deleteReflection(day);
}
