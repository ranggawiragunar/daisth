import '../../../../core/time/domain/models/calendar_day.dart';
import '../models/daily_reflection.dart';
import '../models/reflection_rhythm.dart';
import '../repositories/reflection_repository.dart';

class SaveDailyReflectionUseCase {
  const SaveDailyReflectionUseCase(this.repository);

  static const maxNoteLength = 500;
  final ReflectionRepository repository;

  Future<DailyReflection> call({
    required CalendarDay day,
    required ReflectionRhythm rhythm,
    required String note,
    required DateTime now,
  }) {
    final trimmed = note.trim();
    if (trimmed.length > maxNoteLength) {
      throw ArgumentError.value(note.length, 'note', 'Maximum length is 500.');
    }
    return repository.saveReflection(
      day: day,
      rhythm: rhythm,
      note: trimmed.isEmpty ? null : trimmed,
      now: now,
    );
  }
}
