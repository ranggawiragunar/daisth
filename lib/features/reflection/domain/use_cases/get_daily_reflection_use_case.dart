import '../../../../core/time/domain/models/calendar_day.dart';
import '../models/daily_reflection.dart';
import '../repositories/reflection_repository.dart';

class GetDailyReflectionUseCase {
  const GetDailyReflectionUseCase(this.repository);

  final ReflectionRepository repository;

  Future<DailyReflection?> call(CalendarDay day) =>
      repository.getReflection(day);
}
