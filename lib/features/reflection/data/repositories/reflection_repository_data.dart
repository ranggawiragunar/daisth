import 'dart:async';

import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/models/daily_reflection.dart';
import '../../domain/models/reflection_rhythm.dart';
import '../../domain/repositories/reflection_repository.dart';
import '../mappers/reflection_mapper.dart';
import '../services/reflection_sqlite_service.dart';
import '../../../sync/data/services/sync_outbox_sqlite_helper.dart';

class ReflectionRepositoryData implements ReflectionRepository {
  ReflectionRepositoryData({required this.service, required this.mapper});

  final ReflectionSqliteService service;
  final ReflectionMapper mapper;
  final StreamController<ReflectionChange> _changes =
      StreamController<ReflectionChange>.broadcast();

  @override
  Stream<ReflectionChange> get changes => _changes.stream;

  @override
  Future<DailyReflection?> getReflection(CalendarDay day) async {
    final row = await service.get(day.toDateKey());
    return row == null ? null : mapper.fromData(row);
  }

  @override
  Future<List<DailyReflection>> getReflectionsBetween(
    CalendarDay startDay,
    CalendarDay endDay,
  ) async => List.unmodifiable(
    (await service.getBetween(
      startDay.toDateKey(),
      endDay.toDateKey(),
    )).map(mapper.fromData),
  );

  @override
  Future<CalendarDay?> getEarliestReflectionDay() async {
    final dateKey = await service.getEarliestDateKey();
    return dateKey == null ? null : CalendarDay.parseDateKey(dateKey);
  }

  @override
  Future<DailyReflection> saveReflection({
    required CalendarDay day,
    required ReflectionRhythm rhythm,
    required String? note,
    required DateTime now,
  }) async {
    final row = await service.save(
      dateKey: day.toDateKey(),
      rhythm: rhythm.name,
      note: note,
      now: now,
    );
    final reflection = mapper.fromData(row);
    _changes.add(ReflectionChange(day));
    SyncOutboxSqliteHelper.notifyLocalMutation();
    return reflection;
  }

  @override
  Future<bool> deleteReflection(CalendarDay day) async {
    final deleted = await service.delete(day.toDateKey());
    if (deleted) {
      _changes.add(ReflectionChange(day));
      SyncOutboxSqliteHelper.notifyLocalMutation();
    }
    return deleted;
  }

  Future<void> closeChanges() => _changes.close();
  void notifyRemoteChanged(CalendarDay day) =>
      _changes.add(ReflectionChange(day, isRemoteSync: true));
}
