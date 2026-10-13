import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/location/domain/models/location_access_status.dart';
import 'package:daisth/core/location/domain/repositories/location_repository.dart';
import 'package:daisth/core/location/domain/use_cases/resolve_current_location_use_case.dart';
import 'package:daisth/core/timezone/domain/models/device_timezone.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/core/timezone/domain/repositories/timezone_repository.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_day_schedule.dart';
import 'package:daisth/features/prayer_times/domain/repositories/prayer_time_repository.dart';
import 'package:daisth/features/prayer_times/domain/use_cases/load_today_prayer_schedule_use_case.dart';
import 'package:daisth/features/reminders/domain/models/exact_alarm_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder.dart';
import 'package:daisth/features/reminders/domain/models/reminder_priority.dart';
import 'package:daisth/features/reminders/domain/models/reminder_permission_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder_scheduling_mode.dart';
import 'package:daisth/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:daisth/features/reminders/domain/use_cases/build_today_reminder_plan_use_case.dart';
import 'package:daisth/features/reminders/domain/use_cases/schedule_today_reminders_use_case.dart';
import 'package:daisth/features/reflection/domain/models/reflection_rhythm.dart';
import 'package:daisth/features/reflection/domain/repositories/reflection_repository.dart';
import 'package:daisth/features/reminders/domain/repositories/routine_reminder_state_repository.dart';
import 'package:daisth/features/reminders/data/mappers/routine_reminder_state_mapper.dart';
import 'package:daisth/features/reminders/data/repositories/routine_reminder_state_repository_data.dart';
import 'package:daisth/features/reminders/data/services/routine_reminder_state_sqlite_service.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/routines/data/catalog/default_routine_template_catalog.dart';
import 'package:daisth/features/routines/data/mappers/routine_definition_mapper.dart';
import 'package:daisth/features/routines/data/repositories/routine_repository_data.dart';
import 'package:daisth/features/routines/data/services/routine_sqlite_service.dart';
import 'package:daisth/features/routines/domain/repositories/routine_record_repository.dart';
import 'package:daisth/features/routines/domain/repositories/routine_repository.dart';
import 'package:daisth/features/routines/domain/models/routine_schedule.dart';
import 'package:daisth/features/routines/domain/use_cases/ensure_default_routines_use_case.dart';
import '../support/test_persistence.dart';
import '../support/fake_reflection_repository.dart';

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

  test(
    'Penutup Hari uses its saved primary time and schedules one-hour follow-up',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final definitions = RoutineRepositoryData(
        service: RoutineSqliteService(persistence.database),
        mapper: RoutineDefinitionMapper(),
      );
      await EnsureDefaultRoutinesUseCase(
        repository: definitions,
        templates: DefaultRoutineTemplateCatalog.definitions,
      )(now: DateTime.utc(2026, 10, 1));
      final penutup = (await definitions.getRoutine('penutup-hari'))!;
      await definitions.saveRoutine(
        penutup.copyWith(
          schedule: const FixedRoutineSchedule(22 * 60 + 15),
          updatedAt: DateTime.utc(2026, 10, 1),
        ),
      );
      final states = RoutineReminderStateRepositoryData(
        service: RoutineReminderStateSqliteService(persistence.database),
        mapper: RoutineReminderStateMapper(),
      );
      final reminders = _Reminders(ExactAlarmStatus.enabled);

      await _useCase(
        reminders,
        routineRepository: persistence.routineRecords,
        definitionsRepository: definitions,
        reminderStateRepository: states,
      )(schedule: _schedule(), now: DateTime(2026, 10, 13, 20));

      final penutupReminders = reminders.scheduled
          .where((reminder) => reminder.routineId == 'penutup-hari')
          .toList();
      expect(penutupReminders, hasLength(2));
      expect(penutupReminders.map((reminder) => reminder.scheduledAt), [
        DateTime(2026, 10, 13, 22, 15),
        DateTime(2026, 10, 13, 23, 15),
      ]);
      expect(
        penutupReminders.last.body,
        'Kalau masih memungkinkan, rutinitas ini masih tersedia.',
      );
    },
  );

  test('saved current Reflection suppresses its Open-only reminder', () async {
    final reflectionRepository = FakeReflectionRepository();
    addTearDown(reflectionRepository.close);
    final day = CalendarDay(year: 2026, month: 10, day: 13);
    await reflectionRepository.saveReflection(
      day: day,
      rhythm: ReflectionRhythm.steady,
      note: null,
      now: DateTime.utc(2026, 10, 13, 10),
    );
    final reminders = _Reminders(ExactAlarmStatus.enabled);
    reminders.scheduled.add(
      Reminder(
        id: 'reflection-primary-2026-10-13',
        routineId: 'reflection',
        title: 'Refleksi hari ini',
        body: 'Luangkan sebentar.',
        scheduledAt: DateTime(2026, 10, 13, 20, 30),
        priority: ReminderPriority.medium,
        dateKey: '2026-10-13',
        actionable: false,
        targetType: ReminderTargetType.reflection,
      ),
    );
    final useCase = _useCase(
      reminders,
      reflectionRepository: reflectionRepository,
    );
    final savedSummary = await useCase(
      schedule: _schedule(),
      now: DateTime(2026, 10, 13, 18),
    );
    expect(
      savedSummary.plan.reminders.any(
        (reminder) => reminder.routineId == 'reflection',
      ),
      isFalse,
    );
    expect(
      reminders.scheduled.any((reminder) => reminder.routineId == 'reflection'),
      isFalse,
    );
    expect(reminders.cancelledDates, [DateTime(2026, 10, 13)]);

    await reflectionRepository.deleteReflection(day);
    final clearedSummary = await useCase(
      schedule: _schedule(),
      now: DateTime(2026, 10, 13, 18),
    );
    expect(
      clearedSummary.plan.reminders.any(
        (reminder) => reminder.routineId == 'reflection',
      ),
      isTrue,
    );
  });

  test(
    'clearing after 20:30 does not recreate a retroactive reminder',
    () async {
      final reflectionRepository = FakeReflectionRepository();
      addTearDown(reflectionRepository.close);
      final day = CalendarDay(year: 2026, month: 10, day: 13);
      await reflectionRepository.saveReflection(
        day: day,
        rhythm: ReflectionRhythm.steady,
        note: null,
        now: DateTime.utc(2026, 10, 13, 10),
      );
      final reminders = _Reminders(ExactAlarmStatus.enabled);
      final useCase = _useCase(
        reminders,
        reflectionRepository: reflectionRepository,
      );
      await useCase(schedule: _schedule(), now: DateTime(2026, 10, 13, 21));
      expect(
        reminders.scheduled.any(
          (reminder) => reminder.routineId == 'reflection',
        ),
        isFalse,
      );

      await reflectionRepository.deleteReflection(day);
      final cleared = await useCase(
        schedule: _schedule(),
        now: DateTime(2026, 10, 13, 21, 1),
      );
      expect(
        cleared.plan.reminders.any(
          (reminder) => reminder.routineId == 'reflection',
        ),
        isFalse,
      );
      expect(
        reminders.scheduled.any(
          (reminder) => reminder.routineId == 'reflection',
        ),
        isFalse,
      );
    },
  );

  test(
    'startup reconciliation restores future snooze and skips suppressed/completed follow-up',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final states = RoutineReminderStateRepositoryData(
        service: RoutineReminderStateSqliteService(persistence.database),
        mapper: RoutineReminderStateMapper(),
      );
      final now = DateTime(2026, 10, 13, 3, 15);
      final day = CalendarDay(year: 2026, month: 10, day: 13);
      await states.recordSnooze(
        day: day,
        routineId: 'dhuha',
        snoozedUntil: now.add(const Duration(minutes: 10)),
        now: now,
      );
      await states.suppressFollowUp(day: day, routineId: 'zuhur', now: now);
      await persistence.routineRecords.markCompleted(
        routine: RoutineDemoData.asar,
        day: day,
        now: now,
      );
      await persistence.routineRecords.setStepCompletion(
        routine: RoutineDemoData.sholatMalam,
        day: day,
        stepId: 'tahajud',
        isCompleted: true,
        now: now,
      );
      final reminders = _Reminders(ExactAlarmStatus.enabled);
      await _useCase(
        reminders,
        routineRepository: persistence.routineRecords,
        reminderStateRepository: states,
      )(schedule: _schedule(), now: now);
      expect(
        reminders.scheduled
            .where((r) => r.type == ReminderType.snooze)
            .map((r) => r.routineId),
        ['dhuha'],
      );
      expect(
        reminders.scheduled
            .where((r) => r.type == ReminderType.followUp)
            .map((r) => r.routineId),
        isNot(contains('zuhur')),
      );
      expect(
        reminders.scheduled
            .where((r) => r.type == ReminderType.followUp)
            .map((r) => r.routineId),
        isNot(contains('asar')),
      );
      expect(
        reminders.scheduled
            .where((r) => r.type == ReminderType.followUp)
            .map((r) => r.routineId),
        contains('sholat-malam'),
      );
    },
  );
}

ScheduleTodayRemindersUseCase _useCase(
  _Reminders reminders, {
  RoutineRecordRepository? routineRepository,
  RoutineRepository? definitionsRepository,
  RoutineReminderStateRepository? reminderStateRepository,
  ReflectionRepository? reflectionRepository,
}) => ScheduleTodayRemindersUseCase(
  reminderRepository: reminders,
  timezoneRepository: _Timezones(),
  loadTodayPrayerSchedule: LoadTodayPrayerScheduleUseCase(
    resolveCurrentLocation: ResolveCurrentLocationUseCase(
      locationRepository: _Location(),
    ),
    prayerTimeRepository: _PrayerRepository(),
  ),
  buildTodayReminderPlan: BuildTodayReminderPlanUseCase(),
  routineRecordRepository: routineRepository,
  routineRepository: definitionsRepository,
  reminderStateRepository: reminderStateRepository,
  reflectionRepository: reflectionRepository,
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
  Future<void> cancelRemindersForDate(DateTime date) async {
    cancelledDates.add(date);
    scheduled.removeWhere((reminder) {
      final key = reminder.dateKey;
      return key ==
          '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
    });
  }

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
