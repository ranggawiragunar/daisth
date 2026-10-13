import '../../../../core/time/domain/models/calendar_day.dart';
import '../models/daily_reflection.dart';
import '../models/reflection_rhythm.dart';

class ReflectionChange {
  const ReflectionChange(this.day);

  final CalendarDay day;
}

abstract interface class ReflectionRepository {
  Stream<ReflectionChange> get changes;

  Future<DailyReflection?> getReflection(CalendarDay day);

  Future<List<DailyReflection>> getReflectionsBetween(
    CalendarDay startDay,
    CalendarDay endDay,
  );

  Future<CalendarDay?> getEarliestReflectionDay();

  Future<DailyReflection> saveReflection({
    required CalendarDay day,
    required ReflectionRhythm rhythm,
    required String? note,
    required DateTime now,
  });

  Future<bool> deleteReflection(CalendarDay day);
}
