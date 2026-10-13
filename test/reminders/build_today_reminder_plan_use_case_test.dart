import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/timezone/domain/models/device_timezone.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_day_schedule.dart';
import 'package:daisth/features/reminders/domain/models/reminder_priority.dart';
import 'package:daisth/features/reminders/domain/models/reminder_plan.dart';
import 'package:daisth/features/reminders/domain/use_cases/build_today_reminder_plan_use_case.dart';
import 'package:daisth/features/routines/data/catalog/default_routine_template_catalog.dart';
import 'package:daisth/features/routines/domain/models/routine_definition.dart';
import 'package:daisth/features/routines/domain/models/routine_origin.dart';
import 'package:daisth/features/routines/domain/models/routine_priority.dart';
import 'package:daisth/features/routines/domain/models/routine_schedule.dart';

void main() {
  final builder = BuildTodayReminderPlanUseCase();
  final schedule = _schedule();
  final now = DateTime(2026, 10, 13, 0);

  test('builds all primary reminders with stable IDs and product defaults', () {
    final plan = builder(
      schedule: schedule,
      timezone: const DeviceTimezone(ianaName: 'Asia/Jakarta'),
      now: now,
    );

    expect(plan.reminders, hasLength(9));
    expect(
      plan.reminders.map((reminder) => reminder.id),
      containsAll([
        'subuh-primary-2026-10-13',
        'zuhur-primary-2026-10-13',
        'reflection-primary-2026-10-13',
      ]),
    );
    expect(_time(plan, 'sholat-malam'), '03:00');
    expect(_time(plan, 'subuh'), '04:50');
    expect(_time(plan, 'dhuha'), '07:00');
    expect(_time(plan, 'zuhur'), '11:50');
    expect(_time(plan, 'asar'), '15:20');
    expect(_time(plan, 'maghrib'), '17:50');
    expect(_time(plan, 'isya'), '18:50');
    expect(_time(plan, 'reflection'), '20:30');
    expect(_time(plan, 'penutup-hari'), '21:00');
    expect(
      plan.reminders
          .where(
            (reminder) => {
              'sholat-malam',
              'subuh',
              'zuhur',
              'asar',
              'maghrib',
              'isya',
            }.contains(reminder.routineId),
          )
          .every((reminder) => reminder.priority == ReminderPriority.high),
      isTrue,
    );
    expect(
      plan.reminders
          .where(
            (reminder) => {
              'dhuha',
              'reflection',
              'penutup-hari',
            }.contains(reminder.routineId),
          )
          .every((reminder) => reminder.priority == ReminderPriority.medium),
      isTrue,
    );
    expect(
      plan.reminders.every((reminder) => reminder.scheduledAt.isAfter(now)),
      isTrue,
    );
  });

  test('skips every reminder whose time has passed', () {
    final plan = builder(
      schedule: schedule,
      timezone: const DeviceTimezone(ianaName: 'Asia/Jakarta'),
      now: DateTime(2026, 10, 13, 15),
    );

    expect(plan.reminders.map((reminder) => reminder.routineId), [
      'asar',
      'maghrib',
      'isya',
      'reflection',
      'penutup-hari',
    ]);
  });

  test('preserves local wall-clock times for different IANA zones', () {
    for (final zone in ['Asia/Jakarta', 'America/New_York']) {
      final plan = builder(
        schedule: schedule,
        timezone: DeviceTimezone(ianaName: zone),
        now: now,
      );
      expect(plan.timezone.ianaName, zone);
      expect(_time(plan, 'zuhur'), '11:50');
    }
  });

  test('Penutup Hari uses its configured time and actionable calm copy', () {
    final definition = DefaultRoutineTemplateCatalog.definitions(
      DateTime.utc(2026, 10, 1),
    ).singleWhere((item) => item.id == 'penutup-hari');
    final configured = definition.copyWith(
      schedule: const FixedRoutineSchedule(22 * 60 + 15),
    );
    final plan = builder(
      schedule: schedule,
      timezone: const DeviceTimezone(ianaName: 'Asia/Jakarta'),
      now: now,
      definitions: [configured],
    );
    final reminder = plan.reminders.singleWhere(
      (item) => item.routineId == 'penutup-hari',
    );

    expect(_time(plan, 'penutup-hari'), '22:15');
    expect(reminder.actionable, isTrue);
    expect(reminder.body, 'Siapkan bacaan dan rutinitas sebelum tidur.');
  });

  test(
    'uses active custom definitions and respects reminder configuration',
    () {
      final createdAt = DateTime.utc(2026, 10, 1);
      final custom = RoutineDefinition(
        id: 'custom-reading',
        origin: RoutineOrigin.custom,
        title: 'Morning Reading',
        description: null,
        isEnabled: true,
        isArchived: false,
        schedule: RoutineSchedule.fixed(6 * 60 + 30),
        reminderEnabled: true,
        priority: RoutinePriority.medium,
        sortOrder: 20,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      RoutineDefinition variant(
        String id,
        String title, {
        bool enabled = true,
        bool reminder = true,
      }) => RoutineDefinition(
        id: id,
        origin: RoutineOrigin.custom,
        title: title,
        description: null,
        isEnabled: enabled,
        isArchived: false,
        schedule: RoutineSchedule.fixed(6 * 60 + 30),
        reminderEnabled: reminder,
        priority: RoutinePriority.medium,
        sortOrder: 21,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final disabled = variant('custom-disabled', 'Disabled', enabled: false);
      final muted = variant('custom-muted', 'Muted', reminder: false);
      final dhuha = DefaultRoutineTemplateCatalog.definitions(createdAt)
          .singleWhere((routine) => routine.id == 'dhuha')
          .copyWith(isEnabled: false);

      final plan = builder(
        schedule: schedule,
        timezone: const DeviceTimezone(ianaName: 'Asia/Jakarta'),
        now: now,
        definitions: [custom, disabled, muted, dhuha],
      );

      expect(_time(plan, 'custom-reading'), '06:30');
      expect(plan.reminders.map((reminder) => reminder.routineId), [
        'custom-reading',
        'reflection',
      ]);
    },
  );
}

String _time(ReminderPlan plan, String routineId) {
  final time = plan.reminders
      .firstWhere((reminder) => reminder.routineId == routineId)
      .scheduledAt;
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

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
