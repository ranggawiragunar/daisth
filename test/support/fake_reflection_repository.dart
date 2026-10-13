import 'dart:async';

import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/reflection/domain/models/daily_reflection.dart';
import 'package:daisth/features/reflection/domain/models/reflection_rhythm.dart';
import 'package:daisth/features/reflection/domain/repositories/reflection_repository.dart';

class FakeReflectionRepository implements ReflectionRepository {
  final Map<String, DailyReflection> values = {};
  final StreamController<ReflectionChange> _changes =
      StreamController<ReflectionChange>.broadcast();

  @override
  Stream<ReflectionChange> get changes => _changes.stream;

  @override
  Future<DailyReflection?> getReflection(CalendarDay day) async =>
      values[day.toDateKey()];

  @override
  Future<List<DailyReflection>> getReflectionsBetween(
    CalendarDay startDay,
    CalendarDay endDay,
  ) async => values.values
      .where(
        (value) =>
            value.day.compareTo(startDay) >= 0 &&
            value.day.compareTo(endDay) <= 0,
      )
      .toList(growable: false);

  @override
  Future<CalendarDay?> getEarliestReflectionDay() async {
    if (values.isEmpty) return null;
    return values.values
        .map((value) => value.day)
        .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  }

  @override
  Future<DailyReflection> saveReflection({
    required CalendarDay day,
    required ReflectionRhythm rhythm,
    required String? note,
    required DateTime now,
  }) async {
    final key = day.toDateKey();
    final previous = values[key];
    final current = DailyReflection(
      day: day,
      rhythm: rhythm,
      note: note,
      recordedAt: previous?.recordedAt ?? now.toUtc(),
      updatedAt: now.toUtc(),
    );
    values[key] = current;
    _changes.add(ReflectionChange(day));
    return current;
  }

  @override
  Future<bool> deleteReflection(CalendarDay day) async {
    final deleted = values.remove(day.toDateKey()) != null;
    if (deleted) _changes.add(ReflectionChange(day));
    return deleted;
  }

  Future<void> close() => _changes.close();
}
