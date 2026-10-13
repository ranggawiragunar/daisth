import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/app/dependencies/app_dependencies.dart';
import 'package:daisth/core/app_settings/domain/models/app_settings.dart';
import 'package:daisth/core/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/location/domain/models/location_access_status.dart';
import 'package:daisth/core/location/domain/repositories/location_repository.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/core/timezone/domain/models/device_timezone.dart';
import 'package:daisth/core/timezone/domain/repositories/timezone_repository.dart';
import 'package:daisth/features/reflection/domain/models/reflection_rhythm.dart';
import 'package:daisth/features/reminders/domain/models/exact_alarm_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder.dart';
import 'package:daisth/features/reminders/domain/models/reminder_permission_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder_scheduling_mode.dart';
import 'package:daisth/features/reminders/domain/repositories/reminder_repository.dart';

import '../support/fake_reflection_repository.dart';
import '../support/fake_routine_record_repository.dart';
import '../support/fake_routine_repository.dart';
import '../support/test_persistence.dart';

void main() {
  test(
    'editing a past reflection never calls the OS reminder repository',
    () async {
      final reflectionRepository = FakeReflectionRepository();
      final reminderRepository = _RecordingReminderRepository();
      final dependencies = AppDependencies(
        appSettingsRepository: _EnabledSettingsRepository(),
        locationRepository: _DeniedLocation(),
        reminderRepository: reminderRepository,
        timezoneRepository: _UtcTimezoneRepository(),
        databaseService: TestPersistence.createDatabaseService(),
        routineRepository: FakeRoutineRepository(),
        routineRecordRepository: FakeRoutineRecordRepository(),
        reflectionRepository: reflectionRepository,
        startTodayClock: false,
      );
      addTearDown(dependencies.dispose);
      addTearDown(reflectionRepository.close);

      await dependencies.initialize();
      reminderRepository.operations.clear();

      final pastDay = CalendarDay.fromDateTime(DateTime.now()).addDays(-1);
      await reflectionRepository.saveReflection(
        day: pastDay,
        rhythm: ReflectionRhythm.mixed,
        note: null,
        now: DateTime.now().toUtc(),
      );
      await reflectionRepository.saveReflection(
        day: pastDay,
        rhythm: ReflectionRhythm.heavy,
        note: 'Updated later.',
        now: DateTime.now().toUtc(),
      );
      await reflectionRepository.deleteReflection(pastDay);
      await Future<void>.delayed(Duration.zero);

      expect(reminderRepository.operations, isEmpty);
    },
  );
}

class _EnabledSettingsRepository implements AppSettingsRepository {
  int? onboardingVersion = 1;
  @override
  Future<AppSettings> getSettings() async =>
      const AppSettings(remindersEnabled: true);

  @override
  Future<void> saveSettings(AppSettings settings) async {}

  @override
  Future<int?> getOnboardingVersion() async => onboardingVersion;

  @override
  Future<void> setOnboardingVersion(int version) async {
    onboardingVersion = version;
  }
}

class _UtcTimezoneRepository implements TimezoneRepository {
  static const timezone = DeviceTimezone(ianaName: 'UTC');

  @override
  Future<DeviceTimezone> initialize() async => timezone;

  @override
  Future<DeviceTimezone> getDeviceTimezone() async => timezone;
}

class _DeniedLocation implements LocationRepository {
  @override
  Future<LocationAccessStatus> checkAccess() async =>
      LocationAccessStatus.denied;

  @override
  Future<GeoCoordinate> getCurrentLocation() async =>
      throw StateError('Location is not used in this test.');

  @override
  Future<GeoCoordinate?> getLastKnownLocation() async => null;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<LocationAccessStatus> requestAccess() async =>
      LocationAccessStatus.denied;
}

class _RecordingReminderRepository implements ReminderRepository {
  final List<String> operations = [];

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
  Future<ExactAlarmStatus> getExactAlarmStatus() async =>
      ExactAlarmStatus.enabled;

  @override
  Future<ExactAlarmStatus> requestExactAlarmPermission() async =>
      ExactAlarmStatus.enabled;

  @override
  Future<void> schedule(
    Reminder reminder, {
    required ReminderSchedulingMode mode,
  }) async {
    operations.add('schedule:${reminder.id}');
  }

  @override
  Future<void> cancel(Reminder reminder) async {
    operations.add('cancel:${reminder.id}');
  }

  @override
  Future<void> cancelRemindersForDate(DateTime date) async {
    operations.add('cancel-date:${date.toIso8601String()}');
  }

  @override
  Future<void> cancelAllDaisthReminders() async {
    operations.add('cancel-all');
  }

  @override
  Future<List<Reminder>> getPendingReminders() async => const [];

  @override
  Future<bool> openNotificationSettings() async => true;
}
