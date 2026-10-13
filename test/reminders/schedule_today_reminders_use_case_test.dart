import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/location/domain/models/location_access_status.dart';
import 'package:daisth/core/location/domain/repositories/location_repository.dart';
import 'package:daisth/core/location/domain/use_cases/resolve_current_location_use_case.dart';
import 'package:daisth/core/timezone/domain/models/device_timezone.dart';
import 'package:daisth/core/timezone/domain/repositories/timezone_repository.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_day_schedule.dart';
import 'package:daisth/features/prayer_times/domain/repositories/prayer_time_repository.dart';
import 'package:daisth/features/prayer_times/domain/use_cases/load_today_prayer_schedule_use_case.dart';
import 'package:daisth/features/reminders/domain/models/exact_alarm_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder.dart';
import 'package:daisth/features/reminders/domain/models/reminder_permission_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder_scheduling_mode.dart';
import 'package:daisth/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:daisth/features/reminders/domain/use_cases/build_today_reminder_plan_use_case.dart';
import 'package:daisth/features/reminders/domain/use_cases/schedule_today_reminders_use_case.dart';

void main() {
  test(
    'schedules all future reminders in exact mode and replaces today',
    () async {
      final reminders = _Reminders(ExactAlarmStatus.enabled);
      final useCase = _useCase(reminders);

      final summary = await useCase(
        schedule: _schedule(),
        now: DateTime(2026, 10, 13),
      );

      expect(summary.scheduledCount, 9);
      expect(reminders.cancelledDates, [DateTime(2026, 10, 13)]);
      expect(reminders.scheduled, hasLength(9));
      expect(reminders.modes, everyElement(ReminderSchedulingMode.exact));
      expect(summary.exactAlarmStatus, ExactAlarmStatus.enabled);
    },
  );

  test('uses inexact fallback when exact alarms need permission', () async {
    final reminders = _Reminders(ExactAlarmStatus.needsPermission);
    final summary = await _useCase(reminders)(
      schedule: _schedule(),
      now: DateTime(2026, 10, 13, 15),
    );

    expect(summary.scheduledCount, 5);
    expect(reminders.scheduled, hasLength(5));
    expect(reminders.modes, everyElement(ReminderSchedulingMode.inexact));
    expect(
      reminders.scheduled.every(
        (reminder) => reminder.scheduledAt.isAfter(DateTime(2026, 10, 13, 15)),
      ),
      isTrue,
    );
  });
}

ScheduleTodayRemindersUseCase _useCase(_Reminders reminders) =>
    ScheduleTodayRemindersUseCase(
      reminderRepository: reminders,
      timezoneRepository: _Timezones(),
      loadTodayPrayerSchedule: LoadTodayPrayerScheduleUseCase(
        resolveCurrentLocation: ResolveCurrentLocationUseCase(
          locationRepository: _Location(),
        ),
        prayerTimeRepository: _PrayerRepository(),
      ),
      buildTodayReminderPlan: BuildTodayReminderPlanUseCase(),
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

class _Timezones implements TimezoneRepository {
  @override
  Future<DeviceTimezone> initialize() async =>
      const DeviceTimezone(ianaName: 'Asia/Jakarta');
  @override
  Future<DeviceTimezone> getDeviceTimezone() async =>
      const DeviceTimezone(ianaName: 'Asia/Jakarta');
}

class _Reminders implements ReminderRepository {
  _Reminders(this.exactStatus);

  final ExactAlarmStatus exactStatus;
  final scheduled = <Reminder>[];
  final modes = <ReminderSchedulingMode>[];
  final cancelledDates = <DateTime>[];

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {}
  @override
  Future<String?> getLaunchPayload() async => null;
  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async =>
      ReminderPermissionStatus.granted;
  @override
  Future<ReminderPermissionStatus> requestPermission() async =>
      ReminderPermissionStatus.granted;
  @override
  Future<ExactAlarmStatus> getExactAlarmStatus() async => exactStatus;
  @override
  Future<ExactAlarmStatus> requestExactAlarmPermission() async => exactStatus;
  @override
  Future<void> schedule(
    Reminder reminder, {
    required ReminderSchedulingMode mode,
  }) async {
    scheduled.add(reminder);
    modes.add(mode);
  }

  @override
  Future<void> cancel(Reminder reminder) async {}
  @override
  Future<void> cancelRemindersForDate(DateTime date) async =>
      cancelledDates.add(date);
  @override
  Future<void> cancelAllDaisthReminders() async {}
  @override
  Future<List<Reminder>> getPendingReminders() async => scheduled;
  @override
  Future<bool> openNotificationSettings() async => true;
}

class _Location implements LocationRepository {
  @override
  Future<LocationAccessStatus> checkAccess() async =>
      LocationAccessStatus.granted;
  @override
  Future<LocationAccessStatus> requestAccess() async =>
      LocationAccessStatus.granted;
  @override
  Future<GeoCoordinate> getCurrentLocation() async =>
      const GeoCoordinate(latitude: -6.2, longitude: 106.8);
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
