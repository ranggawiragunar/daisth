import '../../../../core/time/domain/models/calendar_day.dart';
import 'reflection_rhythm.dart';

class DailyReflection {
  const DailyReflection({
    required this.day,
    required this.rhythm,
    required this.note,
    required this.recordedAt,
    required this.updatedAt,
  });

  final CalendarDay day;
  final ReflectionRhythm rhythm;
  final String? note;
  final DateTime recordedAt;
  final DateTime updatedAt;
}
