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
  BuildTodayReminderPlanUseCase({this.languageCode = 'id'});

  String languageCode;

  bool get _english => languageCode.toLowerCase() == 'en';

  String _routineTitle(String id, String fallback) => switch (id) {
    'sholat-malam' => _english ? 'Night Prayer' : 'Sholat Malam',
    'subuh' => _english ? 'Fajr' : 'Subuh',
    'dhuha' => _english ? 'Duha' : 'Dhuha',
    'zuhur' => _english ? 'Dhuhr' : 'Zuhur',
    'asar' => _english ? 'Asr' : 'Asar',
    'maghrib' => 'Maghrib',
    'isya' => _english ? 'Isha' : 'Isya',
    'penutup-hari' => _english ? 'End of Day' : 'Penutup Hari',
    _ => fallback,
  };

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
          targetType: routineId == 'reflection'
              ? ReminderTargetType.reflection
              : ReminderTargetType.routine,
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
              ? _english
                    ? '${_routineTitle(definition.id, definition.title)} is coming up'
                    : 'Waktu ${_routineTitle(definition.id, definition.title)} mendekat'
              : _routineTitle(definition.id, definition.title),
          body: isPrayer
              ? _english
                    ? 'In about 10 minutes.'
                    : 'Sekitar 10 menit lagi.'
              : definition.id == 'penutup-hari'
              ? _english
                    ? 'Take a moment to close your day calmly.'
                    : 'Siapkan bacaan dan rutinitas sebelum tidur.'
              : _english
              ? 'It is time for your planned routine.'
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
      body: 'Luangkan sebentar untuk melihat kembali ritmemu hari ini.',
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
      title: _english ? 'Night Prayer' : 'Sholat Malam',
      body: _english
          ? 'It is time for your planned routine.'
          : 'Waktu yang kamu pilih sudah tiba.',
      scheduledAt: DateTime(date.year, date.month, date.day, 3),
      priority: ReminderPriority.high,
    );
    add(
      routineId: 'subuh',
      title: _english ? 'Fajr is coming up' : 'Subuh segera masuk',
      body: _english ? 'In about 10 minutes.' : 'Sekitar 10 menit lagi.',
      scheduledAt: schedule
          .timeFor(PrayerName.fajr)
          .subtract(const Duration(minutes: 10)),
      priority: ReminderPriority.high,
    );
    add(
      routineId: 'dhuha',
      title: _english ? 'Duha' : 'Waktu Dhuha',
      body: _english
          ? 'There is still time for Duha this morning.'
          : 'Masih ada waktu untuk Dhuha pagi ini.',
      scheduledAt: DateTime(date.year, date.month, date.day, 7),
      priority: ReminderPriority.medium,
    );
    for (final prayer in [
      (
        PrayerName.dhuhr,
        'zuhur',
        _english ? 'Dhuhr is coming up' : 'Waktu Zuhur mendekat',
      ),
      (
        PrayerName.asr,
        'asar',
        _english ? 'Asr is coming up' : 'Waktu Asar mendekat',
      ),
      (
        PrayerName.maghrib,
        'maghrib',
        _english ? 'Maghrib is coming up' : 'Waktu Maghrib mendekat',
      ),
      (
        PrayerName.isha,
        'isya',
        _english ? 'Isha is coming up' : 'Waktu Isya mendekat',
      ),
    ]) {
      add(
        routineId: prayer.$2,
        title: prayer.$3,
        body: _english ? 'In about 10 minutes.' : 'Sekitar 10 menit lagi.',
        scheduledAt: schedule
            .timeFor(prayer.$1)
            .subtract(const Duration(minutes: 10)),
        priority: ReminderPriority.high,
      );
    }
    add(
      routineId: 'penutup-hari',
      title: _english ? 'End of Day' : 'Penutup Hari',
      body: _english
          ? 'Take a moment to close your day calmly.'
          : 'Siapkan bacaan dan rutinitas sebelum tidur.',
      scheduledAt: DateTime(date.year, date.month, date.day).add(
        const Duration(
          minutes: BuiltInRoutineDefaults.penutupHariMinutesAfterMidnight,
        ),
      ),
      priority: ReminderPriority.medium,
    );
  }
}
