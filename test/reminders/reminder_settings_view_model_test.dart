import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/location/domain/models/location_access_status.dart';
import 'package:daisth/core/location/domain/models/location_unavailable_exception.dart';
import 'package:daisth/core/location/domain/repositories/location_repository.dart';
import 'package:daisth/core/location/domain/use_cases/resolve_current_location_use_case.dart';
import 'package:daisth/core/timezone/domain/models/device_timezone.dart';
import 'package:daisth/core/timezone/domain/repositories/timezone_repository.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_day_schedule.dart';
import 'package:daisth/features/prayer_times/domain/repositories/prayer_time_repository.dart';
import 'package:daisth/features/prayer_times/domain/use_cases/load_today_prayer_schedule_use_case.dart';
import 'package:daisth/features/prayer_times/presentation/prayer_schedule_session.dart';
import 'package:daisth/features/reminders/domain/models/exact_alarm_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder.dart';
import 'package:daisth/features/reminders/domain/models/reminder_permission_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder_scheduling_mode.dart';
import 'package:daisth/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:daisth/features/reminders/domain/use_cases/build_today_reminder_plan_use_case.dart';
import 'package:daisth/features/reminders/domain/use_cases/schedule_today_reminders_use_case.dart';
import 'package:daisth/features/reminders/presentation/view_models/reminder_settings_view_model.dart';

import '../support/test_persistence.dart';

void main() {
  test(
    'reminder preference restores without prompting and can be disabled',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final fixture = _fixture(appSettingsRepository: persistence.appSettings);
      addTearDown(fixture.viewModel.dispose);
      addTearDown(fixture.session.dispose);
      await fixture.viewModel.initialize();
      expect(await fixture.viewModel.enableReminders(), isTrue);
      expect(
        (await persistence.appSettings.getSettings()).remindersEnabled,
        isTrue,
      );

      final restored = ReminderSettingsViewModel(
        reminderRepository: fixture.repository,
        timezoneRepository: _TimezoneRepository(),
        scheduleTodayReminders: _scheduleUseCase(fixture.repository),
        prayerScheduleSession: fixture.session,
        appSettingsRepository: persistence.appSettings,
        clock: () => DateTime(2026, 10, 13),
      );
      addTearDown(restored.dispose);
      final permissionRequests = fixture.repository.permissionRequests;
      await restored.initialize();
      expect(restored.remindersEnabled, isTrue);
      expect(fixture.repository.permissionRequests, permissionRequests);
      expect(fixture.repository.scheduled, isNotEmpty);
      expect(
        fixture.repository.scheduled.map((reminder) => reminder.id).toSet(),
        hasLength(fixture.repository.scheduled.length),
      );

      await restored.disableReminders();
      expect(
        (await persistence.appSettings.getSettings()).remindersEnabled,
        isFalse,
      );
      expect(fixture.repository.scheduled, isEmpty);
    },
  );

  test(
    'permission is requested only after enabling; schedule and disable work',
    () async {
      final fixture = _fixture();
      addTearDown(fixture.viewModel.dispose);
      addTearDown(fixture.session.dispose);

      await fixture.viewModel.initialize();
      expect(fixture.viewModel.remindersEnabled, isFalse);
      expect(fixture.repository.permissionRequests, 0);

      expect(await fixture.viewModel.enableReminders(), isTrue);
      expect(fixture.repository.permissionRequests, 1);
      expect(fixture.viewModel.remindersEnabled, isTrue);
      expect(
        fixture.viewModel.exactAlarmStatus,
        ExactAlarmStatus.needsPermission,
      );
      expect(fixture.repository.scheduled, isNotEmpty);
      expect(
        fixture.repository.modes,
        everyElement(ReminderSchedulingMode.inexact),
      );
      expect(fixture.viewModel.scheduledTodayCount, greaterThan(0));

      await fixture.viewModel.requestExactAlarmPermission();
      expect(fixture.viewModel.exactAlarmStatus, ExactAlarmStatus.enabled);
      expect(fixture.repository.modes.last, ReminderSchedulingMode.exact);

      await fixture.viewModel.disableReminders();
      expect(fixture.viewModel.remindersEnabled, isFalse);
      expect(fixture.repository.cancelAllCount, 1);
    },
  );

  test('denied notification permission leaves reminders off', () async {
    final fixture = _fixture(
      requestedPermission: ReminderPermissionStatus.denied,
    );
    addTearDown(fixture.viewModel.dispose);
    addTearDown(fixture.session.dispose);

    await fixture.viewModel.initialize();
    expect(await fixture.viewModel.enableReminders(), isFalse);
    expect(fixture.viewModel.permissionStatus, ReminderPermissionStatus.denied);
    expect(fixture.viewModel.remindersEnabled, isFalse);
    expect(fixture.repository.scheduled, isEmpty);
    expect(fixture.viewModel.errorMessage, contains('Izinkan notifikasi'));
  });

  test('location failure explains why reminders remain off', () async {
    final fixture = _fixture(locationUnavailable: true, hasSchedule: false);
    addTearDown(fixture.viewModel.dispose);
    addTearDown(fixture.session.dispose);

    await fixture.viewModel.initialize();

    expect(await fixture.viewModel.enableReminders(), isFalse);
    expect(fixture.viewModel.remindersEnabled, isFalse);
    expect(fixture.repository.scheduled, isEmpty);
    expect(
      fixture.viewModel.errorMessage,
      contains('Muat waktu salat di Pengaturan'),
    );
  });

  test(
    'app resume refreshes device permissions while reminders are off',
    () async {
      final fixture = _fixture();
      addTearDown(fixture.viewModel.dispose);
      addTearDown(fixture.session.dispose);
      await fixture.viewModel.initialize();
      expect(fixture.viewModel.remindersEnabled, isFalse);
      expect(
        fixture.viewModel.permissionStatus,
        ReminderPermissionStatus.denied,
      );

      fixture.repository.currentPermission = ReminderPermissionStatus.granted;
      fixture.repository.exactStatus = ExactAlarmStatus.enabled;
      await fixture.viewModel.onAppResumed();

      expect(
        fixture.viewModel.permissionStatus,
        ReminderPermissionStatus.granted,
      );
      expect(fixture.viewModel.exactAlarmStatus, ExactAlarmStatus.enabled);
      expect(fixture.viewModel.deviceTimezone?.ianaName, 'Asia/Jakarta');
      expect(fixture.repository.scheduled, isEmpty);
    },
  );
}

({
  ReminderSettingsViewModel viewModel,
  _ReminderRepository repository,
  PrayerScheduleSession session,
})
_fixture({
  ReminderPermissionStatus requestedPermission =
      ReminderPermissionStatus.granted,
  AppSettingsRepository? appSettingsRepository,
  bool locationUnavailable = false,
  bool hasSchedule = true,
}) {
  final now = DateTime(2026, 10, 13);
  final schedule = _schedule();
  final session = PrayerScheduleSession(
    _loadScheduleUseCase(locationUnavailable: locationUnavailable),
  );
  if (hasSchedule) {
    session.schedule = schedule;
    session.lastUpdated = now;
  }
  final repository = _ReminderRepository(
    requestedPermission: requestedPermission,
  );
  final useCase = ScheduleTodayRemindersUseCase(
    reminderRepository: repository,
    timezoneRepository: _TimezoneRepository(),
    loadTodayPrayerSchedule: _loadScheduleUseCase(
      locationUnavailable: locationUnavailable,
    ),
    buildTodayReminderPlan: BuildTodayReminderPlanUseCase(),
    clock: () => now,
  );
  return (
    viewModel: ReminderSettingsViewModel(
      reminderRepository: repository,
      timezoneRepository: _TimezoneRepository(),
      scheduleTodayReminders: useCase,
      prayerScheduleSession: session,
      appSettingsRepository: appSettingsRepository,
      clock: () => now,
    ),
    repository: repository,
    session: session,
  );
}

ScheduleTodayRemindersUseCase _scheduleUseCase(ReminderRepository repository) =>
    ScheduleTodayRemindersUseCase(
      reminderRepository: repository,
      timezoneRepository: _TimezoneRepository(),
      loadTodayPrayerSchedule: _loadScheduleUseCase(),
      buildTodayReminderPlan: BuildTodayReminderPlanUseCase(),
      clock: () => DateTime(2026, 10, 13),
    );

LoadTodayPrayerScheduleUseCase _loadScheduleUseCase({
  bool locationUnavailable = false,
}) => LoadTodayPrayerScheduleUseCase(
  resolveCurrentLocation: ResolveCurrentLocationUseCase(
    locationRepository: _LocationRepository(
      locationUnavailable: locationUnavailable,
    ),
  ),
  prayerTimeRepository: _PrayerRepository(),
);

PrayerDaySchedule _schedule() => PrayerDaySchedule(
  date: DateTime(2026, 10, 13),
  coordinate: const GeoCoordinate(latitude: -6.2, longitude: 106.8),
  fajr: DateTime(2026, 10, 13, 5),
  sunrise: DateTime(2026, 10, 13, 6),
  dhuhr: DateTime(2026, 10, 13, 12),
  asr: DateTime(2026, 10, 13, 15, 30),
  maghrib: DateTime(2026, 10, 13, 18),
  isha: DateTime(2026, 10, 13, 19),
  calculationSettings: PrayerCalculationSettings.defaultSettings,
);

class _TimezoneRepository implements TimezoneRepository {
  @override
  Future<DeviceTimezone> initialize() async => getDeviceTimezone();
  @override
  Future<DeviceTimezone> getDeviceTimezone() async =>
      const DeviceTimezone(ianaName: 'Asia/Jakarta');
}

class _ReminderRepository implements ReminderRepository {
  _ReminderRepository({
    this.requestedPermission = ReminderPermissionStatus.granted,
  });

  final ReminderPermissionStatus requestedPermission;
  ReminderPermissionStatus currentPermission = ReminderPermissionStatus.denied;
  final scheduled = <Reminder>[];
  final modes = <ReminderSchedulingMode>[];
  int permissionRequests = 0;
  int cancelAllCount = 0;
  ExactAlarmStatus exactStatus = ExactAlarmStatus.needsPermission;

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {}
  @override
  Future<String?> getLaunchPayload() async => null;
  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async =>
      currentPermission;
  @override
  Future<ReminderPermissionStatus> requestPermission() async {
    permissionRequests++;
    currentPermission = requestedPermission;
    return currentPermission;
  }

  @override
  Future<ExactAlarmStatus> getExactAlarmStatus() async => exactStatus;
  @override
  Future<ExactAlarmStatus> requestExactAlarmPermission() async {
    exactStatus = ExactAlarmStatus.enabled;
    return exactStatus;
  }

  @override
  Future<void> schedule(
    Reminder reminder, {
    required ReminderSchedulingMode mode,
  }) async {
    scheduled.removeWhere((existing) => existing.id == reminder.id);
    scheduled.add(reminder);
    modes.add(mode);
  }

  @override
  Future<void> cancel(Reminder reminder) async {}
  @override
  Future<void> cancelRemindersForDate(DateTime date) async {
    scheduled.removeWhere(
      (reminder) =>
          reminder.scheduledAt.year == date.year &&
          reminder.scheduledAt.month == date.month &&
          reminder.scheduledAt.day == date.day,
    );
  }

  @override
  Future<void> cancelAllDaisthReminders() async {
    cancelAllCount++;
    scheduled.clear();
  }

  @override
  Future<List<Reminder>> getPendingReminders() async => List.of(scheduled);
  @override
  Future<bool> openNotificationSettings() async => true;
}

class _LocationRepository implements LocationRepository {
  _LocationRepository({this.locationUnavailable = false});

  final bool locationUnavailable;

  @override
  Future<LocationAccessStatus> checkAccess() async =>
      LocationAccessStatus.granted;
  @override
  Future<LocationAccessStatus> requestAccess() async =>
      LocationAccessStatus.granted;
  @override
  Future<GeoCoordinate> getCurrentLocation() async {
    if (locationUnavailable) throw const LocationUnavailableException();
    return const GeoCoordinate(latitude: -6.2, longitude: 106.8);
  }

  @override
  Future<GeoCoordinate?> getLastKnownLocation() async => null;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}

class _PrayerRepository implements PrayerTimeRepository {
  @override
  Future<PrayerDaySchedule> calculateSchedule({
    required GeoCoordinate coordinate,
    required DateTime date,
    PrayerCalculationSettings settings =
        PrayerCalculationSettings.defaultSettings,
  }) async => _schedule();
}
