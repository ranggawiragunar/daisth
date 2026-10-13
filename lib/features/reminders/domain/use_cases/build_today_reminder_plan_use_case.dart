import '../../../../core/timezone/domain/models/device_timezone.dart';
import '../../../prayer_times/domain/models/prayer_day_schedule.dart';
import '../../../prayer_times/domain/models/prayer_name.dart';
import '../../../routines/domain/models/prayer_key.dart';
import '../../../routines/domain/models/routine_definition.dart';
import '../../../routines/domain/models/routine_priority.dart'
    as routine_priority;
import '../../../routines/domain/models/routine_schedule.dart';
import '../../../routines/domain/models/built_in_routine_defaults.dart';
import '../models/reminder.dart';
import '../models/reminder_plan.dart';
import '../models/reminder_priority.dart';

class BuildTodayReminderPlanUseCase {
  ReminderPlan call({
    required PrayerDaySchedule schedule,
    required DeviceTimezone timezone,
    required DateTime now,
    bool includePast = false,
    List<RoutineDefinition>? definitions,
  }) {
    final date = DateTime(
      schedule.date.year,
      schedule.date.month,
      schedule.date.day,
    );
    final reminders = <Reminder>[];
    void add({
      required String routineId,
      required String title,
      required String body,
      required DateTime scheduledAt,
      required ReminderPriority priority,
    }) {
      if (!includePast && !scheduledAt.isAfter(now)) return;
      reminders.add(
        Reminder(
          id: '$routineId-primary-${_dateKey(date)}',
          routineId: routineId,
          title: title,
          body: body,
          scheduledAt: scheduledAt,
          priority: priority,
          dateKey: _dateKey(date),
          timezoneIdentifier: timezone.ianaName,
          actionable: routineId != 'reflection',
        ),
      );
    }

    if (definitions == null) {
      _addLegacyDefaults(add, date, schedule);
    } else {
      for (final definition in definitions.where(
        (item) => item.isEnabled && !item.isArchived && item.reminderEnabled,
      )) {
        final scheduledAt = switch (definition.schedule) {
          FixedRoutineSchedule(:final value) => DateTime(
            date.year,
            date.month,
            date.day,
          ).add(Duration(minutes: value)),
          PrayerRoutineSchedule(:final value) => schedule.timeFor(
            _prayer(value),
          ),
        };
        final isPrayer = definition.schedule is PrayerRoutineSchedule;
        add(
          routineId: definition.id,
          title: isPrayer
              ? 'Waktu ${definition.title} mendekat'
              : definition.title,
          body: isPrayer
              ? 'Sekitar 10 menit lagi.'
              : definition.id == 'penutup-hari'
              ? 'Siapkan bacaan dan rutinitas sebelum tidur.'
              : 'Waktu yang kamu pilih sudah tiba.',
          scheduledAt: isPrayer
              ? scheduledAt.subtract(const Duration(minutes: 10))
              : scheduledAt,
          priority: switch (definition.priority) {
            routine_priority.RoutinePriority.high => ReminderPriority.high,
            routine_priority.RoutinePriority.medium => ReminderPriority.medium,
            routine_priority.RoutinePriority.low => ReminderPriority.low,
          },
        );
      }
    }
    add(
      routineId: 'reflection',
      title: 'Refleksi hari ini',
      body: 'Luangkan waktu sebentar untuk melihat kembali rutinitasmu.',
      scheduledAt: DateTime(date.year, date.month, date.day, 20, 30),
      priority: ReminderPriority.medium,
    );
    reminders.sort(
      (first, second) => first.scheduledAt.compareTo(second.scheduledAt),
    );
    return ReminderPlan(date: date, timezone: timezone, reminders: reminders);
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  PrayerName _prayer(PrayerKey key) => switch (key) {
    PrayerKey.subuh => PrayerName.fajr,
    PrayerKey.zuhur => PrayerName.dhuhr,
    PrayerKey.asar => PrayerName.asr,
    PrayerKey.maghrib => PrayerName.maghrib,
    PrayerKey.isya => PrayerName.isha,
  };

  void _addLegacyDefaults(
    void Function({
      required String routineId,
      required String title,
      required String body,
      required DateTime scheduledAt,
      required ReminderPriority priority,
    })
    add,
    DateTime date,
    PrayerDaySchedule schedule,
  ) {
    add(
      routineId: 'sholat-malam',
      title: 'Sholat Malam',
      body: 'Waktu yang kamu pilih sudah tiba.',
      scheduledAt: DateTime(date.year, date.month, date.day, 3),
      priority: ReminderPriority.high,
    );
    add(
      routineId: 'subuh',
      title: 'Subuh segera masuk',
      body: 'Sekitar 10 menit lagi.',
      scheduledAt: schedule
          .timeFor(PrayerName.fajr)
          .subtract(const Duration(minutes: 10)),
      priority: ReminderPriority.high,
    );
    add(
      routineId: 'dhuha',
      title: 'Waktu Dhuha',
      body: 'Masih ada waktu untuk Dhuha pagi ini.',
      scheduledAt: DateTime(date.year, date.month, date.day, 7),
      priority: ReminderPriority.medium,
    );
    for (final prayer in [
      (PrayerName.dhuhr, 'zuhur', 'Waktu Zuhur mendekat'),
      (PrayerName.asr, 'asar', 'Waktu Asar mendekat'),
      (PrayerName.maghrib, 'maghrib', 'Waktu Maghrib mendekat'),
      (PrayerName.isha, 'isya', 'Waktu Isya mendekat'),
    ]) {
      add(
        routineId: prayer.$2,
        title: prayer.$3,
        body: 'Sekitar 10 menit lagi.',
        scheduledAt: schedule
            .timeFor(prayer.$1)
            .subtract(const Duration(minutes: 10)),
        priority: ReminderPriority.high,
      );
    }
    add(
      routineId: 'penutup-hari',
      title: 'Penutup Hari',
      body: 'Siapkan bacaan dan rutinitas sebelum tidur.',
      scheduledAt: DateTime(date.year, date.month, date.day).add(
        const Duration(
          minutes: BuiltInRoutineDefaults.penutupHariMinutesAfterMidnight,
        ),
      ),
      priority: ReminderPriority.medium,
    );
  }
}
