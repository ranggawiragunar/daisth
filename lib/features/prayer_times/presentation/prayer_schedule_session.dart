import 'package:flutter/foundation.dart';

import '../../../core/location/domain/models/location_access_status.dart';
import '../../../core/location/domain/models/location_unavailable_exception.dart';
import '../domain/models/loaded_prayer_schedule.dart';
import '../domain/models/prayer_day_schedule.dart';
import '../domain/use_cases/load_today_prayer_schedule_use_case.dart';

class PrayerScheduleSession extends ChangeNotifier {
  PrayerScheduleSession(this.loadTodayPrayerSchedule);

  final LoadTodayPrayerScheduleUseCase loadTodayPrayerSchedule;

  PrayerDaySchedule? schedule;
  LocationAccessStatus? accessStatus;
  DateTime? lastUpdated;
  bool usedLastKnownLocation = false;
  bool isCheckingAccess = false;
  bool isLoading = false;
  bool isLocationUnavailable = false;
  Object? calculationError;
  bool _initialized = false;
  DateTime? _loadedCalendarDate;

  bool get hasSchedule => schedule != null;

  Future<void> initialize({DateTime? now}) async {
    if (_initialized &&
        _isSameDay(_loadedCalendarDate, now ?? DateTime.now())) {
      return;
    }
    _initialized = true;
    await _checkAccessAndMaybeLoad(now: now);
  }

  Future<void> requestLocation({DateTime? now}) async {
    isCheckingAccess = true;
    calculationError = null;
    notifyListeners();
    try {
      accessStatus = await loadTodayPrayerSchedule.requestLocationAccess();
      if (accessStatus == LocationAccessStatus.granted) {
        await _load(now: now);
      }
    } catch (error) {
      calculationError = error;
    } finally {
      isCheckingAccess = false;
      notifyListeners();
    }
  }

  Future<void> refresh({DateTime? now, bool requestPermission = false}) async {
    await _checkAccessAndMaybeLoad(
      now: now,
      requestPermission: requestPermission,
    );
  }

  Future<void> refreshIfStale({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final dateChanged = !_isSameDay(_loadedCalendarDate, current);
    final stale =
        lastUpdated == null ||
        current.difference(lastUpdated!) > const Duration(hours: 6);
    if (dateChanged || stale) await refresh(now: current);
  }

  Future<void> openAppSettings() async {
    await loadTodayPrayerSchedule.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await loadTodayPrayerSchedule.openLocationSettings();
  }

  Future<void> _checkAccessAndMaybeLoad({
    DateTime? now,
    bool requestPermission = false,
  }) async {
    if (isLoading || isCheckingAccess) return;
    isCheckingAccess = true;
    calculationError = null;
    notifyListeners();
    try {
      accessStatus = await loadTodayPrayerSchedule.checkLocationAccess();
      if (accessStatus != LocationAccessStatus.granted && requestPermission) {
        accessStatus = await loadTodayPrayerSchedule.requestLocationAccess();
      }
      if (accessStatus == LocationAccessStatus.granted) {
        await _load(now: now);
      }
    } catch (error) {
      calculationError = error;
    } finally {
      isCheckingAccess = false;
      notifyListeners();
    }
  }

  Future<void> _load({DateTime? now}) async {
    isLoading = true;
    isLocationUnavailable = false;
    calculationError = null;
    notifyListeners();
    try {
      final LoadedPrayerSchedule loaded = await loadTodayPrayerSchedule(
        date: now ?? DateTime.now(),
      );
      schedule = loaded.schedule;
      usedLastKnownLocation = loaded.usedLastKnownLocation;
      _loadedCalendarDate = loaded.schedule.date;
      lastUpdated = DateTime.now();
    } on LocationUnavailableException {
      isLocationUnavailable = true;
    } catch (error) {
      calculationError = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _isSameDay(DateTime? date, DateTime other) =>
      date != null &&
      date.year == other.year &&
      date.month == other.month &&
      date.day == other.day;
}
