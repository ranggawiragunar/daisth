import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/models/daily_reflection.dart';
import '../../domain/models/reflection_rhythm.dart';

class ReflectionMapper {
  DailyReflection fromData(Map<String, Object?> data) {
    final rhythmValue = data['rhythm'] as String;
    final rhythm = ReflectionRhythm.values
        .where((value) => value.name == rhythmValue)
        .firstOrNull;
    if (rhythm == null) {
      throw FormatException('Unknown reflection rhythm.', rhythmValue);
    }
    final note = data['note'] as String?;
    return DailyReflection(
      day: CalendarDay.parseDateKey(data['date_key'] as String),
      rhythm: rhythm,
      note: note == null || note.trim().isEmpty ? null : note,
      recordedAt: DateTime.parse(data['recorded_at_utc'] as String).toUtc(),
      updatedAt: DateTime.parse(data['updated_at_utc'] as String).toUtc(),
    );
  }
}
