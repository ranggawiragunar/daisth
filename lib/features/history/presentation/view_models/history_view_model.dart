import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/time/domain/models/calendar_day.dart';
import '../../../routines/domain/repositories/routine_record_repository.dart';
import '../../domain/models/history_day.dart';
import '../../domain/use_cases/get_history_range_use_case.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({required this.getHistory, required this.repository}) {
    _subscription = repository.changes.listen((_) => unawaited(refresh()));
  }

  final GetHistoryRangeUseCase getHistory;
  final RoutineRecordRepository repository;
  late final StreamSubscription<RoutineRecordChange> _subscription;
  List<HistoryDay> days = const [];
  bool isLoading = true;
  bool isLoadingEarlier = false;
  bool hasEarlier = false;
  bool hasMeaningfulHistory = true;
  String? errorMessage;
  bool _disposed = false;

  Future<void> initialize() async {
    isLoading = true;
    _notify();
    try {
      final page = await getHistory.initial();
      days = page.days;
      hasEarlier = page.hasEarlier;
      hasMeaningfulHistory = page.earliestDay != null;
      errorMessage = null;
    } catch (_) {
      errorMessage = 'History belum dapat dimuat. Coba lagi.';
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    if (isLoading || days.isEmpty) return initialize();
    try {
      final pages = <HistoryDay>[];
      var cursor = days.first.day.addDays(1);
      final oldest = days.last.day;
      while (true) {
        final page = await getHistory.loadBefore(cursor);
        pages.addAll(page.days);
        hasEarlier = page.hasEarlier;
        if (!page.hasEarlier ||
            page.days.isEmpty ||
            page.days.last.day == oldest) {
          break;
        }
        cursor = page.days.last.day;
      }
      days = pages;
      errorMessage = null;
      _notify();
    } catch (_) {
      errorMessage = 'History belum dapat dimuat. Coba lagi.';
      _notify();
    }
  }

  Future<void> loadEarlier() async {
    if (!hasEarlier || isLoadingEarlier || days.isEmpty) return;
    isLoadingEarlier = true;
    _notify();
    try {
      final page = await getHistory.loadBefore(days.last.day);
      final existing = days.map((item) => item.day.toDateKey()).toSet();
      days = List.unmodifiable([
        ...days,
        ...page.days.where((item) => !existing.contains(item.day.toDateKey())),
      ]);
      hasEarlier = page.hasEarlier;
      hasMeaningfulHistory = page.earliestDay != null;
      errorMessage = null;
    } catch (_) {
      errorMessage = 'History sebelumnya belum dapat dimuat. Coba lagi.';
    } finally {
      isLoadingEarlier = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class HistoryDayViewModel extends ChangeNotifier {
  HistoryDayViewModel({
    required this.day,
    required this.loadDay,
    required this.repository,
  }) {
    _subscription = repository.changes.listen((change) {
      if (change.calendarDay == day) unawaited(reload());
    });
  }

  final CalendarDay day;
  final Future<HistoryDay> Function(CalendarDay) loadDay;
  final RoutineRecordRepository repository;
  late final StreamSubscription<RoutineRecordChange> _subscription;
  Future<HistoryDay>? future;
  bool _disposed = false;

  void initialize() => future = loadDay(day);

  Future<void> reload() async {
    future = loadDay(day);
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
