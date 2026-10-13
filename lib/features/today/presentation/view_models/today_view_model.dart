import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/location/domain/models/location_access_status.dart';
import '../../../../core/time/domain/models/calendar_day.dart';
import '../../../routines/domain/models/routine_status.dart' as routine_domain;
import '../../../routines/domain/repositories/routine_record_repository.dart';
import '../../../prayer_times/domain/models/prayer_period_state.dart';
import '../../../prayer_times/domain/use_cases/resolve_current_prayer_period_use_case.dart';
import '../../../prayer_times/presentation/prayer_schedule_session.dart';

class TodayViewModel extends ChangeNotifier {
  TodayViewModel({
    required this.prayerScheduleSession,
    required this.routineRecordRepository,
    DateTime Function()? clock,
    bool startClock = true,
  }) : _clock = clock ?? DateTime.now,
       now = (clock ?? DateTime.now)() {
    prayerScheduleSession.addListener(_onSessionChanged);
    _recordSubscription = routineRecordRepository.changes.listen((change) {
      if (change.calendarDay == CalendarDay.fromDateTime(now)) {
        unawaited(refreshRoutineRecords());
      }
    });
    if (startClock) {
      _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    }
  }

  final PrayerScheduleSession prayerScheduleSession;
  final RoutineRecordRepository routineRecordRepository;
  final DateTime Function() _clock;
  final ResolveCurrentPrayerPeriodUseCase _resolveCurrentPeriod =
      const ResolveCurrentPrayerPeriodUseCase();
  Timer? _clockTimer;
  late final StreamSubscription<RoutineRecordChange> _recordSubscription;
  Map<String, routine_domain.RoutineStatus> recordedStatuses = const {};
  DateTime now;

  Future<void> initialize() async {
    await Future.wait([
      prayerScheduleSession.initialize(now: now),
      refreshRoutineRecords(),
    ]);
  }

  Future<void> refreshRoutineRecords() async {
    final records = await routineRecordRepository.getRecordsForDay(
      CalendarDay.fromDateTime(now),
    );
    recordedStatuses = {
      for (final record in records) record.routineId: record.status,
    };
    notifyListeners();
  }

  Future<void> refresh() => prayerScheduleSession.refresh(now: now);

  Future<void> requestLocation() =>
      prayerScheduleSession.requestLocation(now: now);

  Future<void> openAppSettings() => prayerScheduleSession.openAppSettings();

  Future<void> openLocationSettings() =>
      prayerScheduleSession.openLocationSettings();

  Future<void> onAppResumed() async {
    now = _clock();
    notifyListeners();
    await refreshRoutineRecords();
    await prayerScheduleSession.refreshIfStale(now: now);
  }

  PrayerPeriodState? get currentPeriod {
    final schedule = prayerScheduleSession.schedule;
    return schedule == null
        ? null
        : _resolveCurrentPeriod(schedule: schedule, now: now);
  }

  void _tick() {
    final oldNow = now;
    now = _clock();
    if (!_sameDay(oldNow, now)) {
      unawaited(refreshRoutineRecords());
      unawaited(prayerScheduleSession.refreshIfStale(now: now));
    }
    notifyListeners();
  }

  void _onSessionChanged() => notifyListeners();

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  LocationAccessStatus? get accessStatus => prayerScheduleSession.accessStatus;
  bool get isCheckingAccess => prayerScheduleSession.isCheckingAccess;
  bool get isLoading => prayerScheduleSession.isLoading;
  bool get usedLastKnownLocation => prayerScheduleSession.usedLastKnownLocation;
  bool get isLocationUnavailable => prayerScheduleSession.isLocationUnavailable;
  Object? get calculationError => prayerScheduleSession.calculationError;

  @override
  void dispose() {
    _clockTimer?.cancel();
    _recordSubscription.cancel();
    prayerScheduleSession.removeListener(_onSessionChanged);
    super.dispose();
  }
}
