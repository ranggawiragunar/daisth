import '../../../../core/timezone/domain/repositories/timezone_repository.dart';
import '../../../../core/time/domain/models/calendar_day.dart';
import '../../../prayer_times/domain/models/prayer_day_schedule.dart';
import '../../../prayer_times/domain/use_cases/load_today_prayer_schedule_use_case.dart';
import '../models/exact_alarm_status.dart';
import '../models/reminder.dart';
import '../models/reminder_priority.dart';
import '../models/routine_reminder_state.dart';
import '../models/reminder_schedule_summary.dart';
import '../models/reminder_plan.dart';
import '../models/reminder_scheduling_mode.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/routine_reminder_state_repository.dart';
import '../../../routines/domain/models/routine_status.dart';
import '../../../routines/domain/repositories/routine_record_repository.dart';
import '../../../routines/domain/repositories/routine_repository.dart';
import '../../../routines/domain/models/routine_origin.dart';
import '../../../reflection/domain/repositories/reflection_repository.dart';
import 'build_today_reminder_plan_use_case.dart';
import 'reminder_follow_up_policy.dart';

class ScheduleTodayRemindersUseCase {
  ScheduleTodayRemindersUseCase({required this.reminderRepository, required this.timezoneRepository, required this.loadTodayPrayerSchedule, required this.buildTodayReminderPlan, this.routineRecordRepository, this.routineRepository, this.reminderStateRepository, this.reflectionRepository, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ReminderRepository reminderRepository;
  final TimezoneRepository timezoneRepository;
  final LoadTodayPrayerScheduleUseCase loadTodayPrayerSchedule;
  final BuildTodayReminderPlanUseCase buildTodayReminderPlan;
  final RoutineRecordRepository? routineRecordRepository;
  final RoutineRepository? routineRepository;
  final RoutineReminderStateRepository? reminderStateRepository;
  final ReflectionRepository? reflectionRepository;
  final DateTime Function() _clock;
  static const _followUpPolicy = ReminderFollowUpPolicy();

  bool get _english => buildTodayReminderPlan.languageCode.toLowerCase() == 'en';

  Future<ReminderScheduleSummary> call({PrayerDaySchedule? schedule, DateTime? now}) async {
    final current = now ?? _clock();
    var todaySchedule = schedule;
    if (todaySchedule == null || !_isSameDate(todaySchedule.date, current)) {
      todaySchedule = (await loadTodayPrayerSchedule(date: current)).schedule;
    }
    final deviceTimezone = await timezoneRepository.getDeviceTimezone();
    final activeDefinitions = await routineRepository?.getActiveRoutines();
    final completePlan = buildTodayReminderPlan(schedule: todaySchedule, timezone: deviceTimezone, now: current, includePast: true, definitions: activeDefinitions);
    final day = CalendarDay.fromDateTime(completePlan.date);
    final hasReflection = await reflectionRepository?.getReflection(day) != null;
    final plan = ReminderPlan(date: completePlan.date, timezone: completePlan.timezone, reminders: completePlan.reminders.where((reminder) => reminder.scheduledAt.isAfter(current) && !(hasReflection && reminder.routineId == 'reflection')).toList());
    final exactStatus = await reminderRepository.getExactAlarmStatus();
    final mode = exactStatus == ExactAlarmStatus.enabled ? ReminderSchedulingMode.exact : ReminderSchedulingMode.inexact;

    var states = await reminderStateRepository?.getStatesForDay(day) ?? const <RoutineReminderState>[];
    if (reminderStateRepository != null) {
      final dateKey = day.toDateKey();
      for (final pending in await reminderRepository.getPendingReminders()) {
        if (pending.type != ReminderType.snooze || pending.dateKey != dateKey || !pending.scheduledAt.isAfter(current)) {
          continue;
        }
        final persisted = states.where((state) => state.routineId == pending.routineId).firstOrNull;
        if (persisted == null || persisted.snoozedUntil == null || pending.scheduledAt.isAfter(persisted.snoozedUntil!)) {
          await reminderStateRepository!.recordSnooze(day: day, routineId: pending.routineId, snoozedUntil: pending.scheduledAt, now: current);
        }
      }
      states = await reminderStateRepository!.getStatesForDay(day);
    }
    await reminderRepository.cancelRemindersForDate(plan.date);
    var scheduledCount = 0;
    for (final reminder in plan.reminders) {
      await reminderRepository.schedule(reminder, mode: mode);
      scheduledCount++;
    }
    if (routineRecordRepository != null && reminderStateRepository != null) {
      final stateByRoutine = {for (final state in states) state.routineId: state};
      final followUpIds = activeDefinitions == null ? _actionableRoutineIds : activeDefinitions.where((definition) => definition.reminderEnabled && (ReminderFollowUpPolicy.supportedRoutineIds.contains(definition.id) || definition.origin == RoutineOrigin.custom)).map((definition) => definition.id).toList(growable: false);
      for (final routineId in followUpIds) {
        final record = await routineRecordRepository!.getRoutineRecord(day, routineId);
        if (record?.status == RoutineStatus.completed || record?.status == RoutineStatus.notToday) {
          continue;
        }
        final state = stateByRoutine[routineId];
        if (state?.snoozedUntil case final snooze? when snooze.isAfter(current)) {
          final primary = completePlan.reminders.where((r) => r.routineId == routineId).firstOrNull ?? _template(routineId, plan.date, deviceTimezone.ianaName);
          await reminderRepository.schedule(_makeReminder(primary, 'snooze', snooze), mode: mode);
          scheduledCount++;
        }
        if (state?.followUpSuppressed == true) continue;
        final primary = completePlan.reminders.where((r) => r.routineId == routineId).firstOrNull ?? _template(routineId, plan.date, deviceTimezone.ianaName);
        final existing = state?.followUpScheduledAt;
        final followUpAt = existing != null && existing.isAfter(current) ? existing : _followUpPolicy.scheduleAt(routineId: routineId, primaryAt: primary.scheduledAt, prayerSchedule: todaySchedule, now: current);
        if (followUpAt == null || !followUpAt.isAfter(current)) continue;
        final followUp = _makeReminder(primary, 'follow-up', followUpAt);
        await reminderRepository.schedule(followUp, mode: mode);
        scheduledCount++;
        await reminderStateRepository!.recordFollowUpScheduled(day: day, routineId: routineId, scheduledAt: followUpAt, now: current);
      }
    }
    return ReminderScheduleSummary(plan: plan, scheduledCount: scheduledCount, exactAlarmStatus: exactStatus);
  }

  bool _isSameDate(DateTime first, DateTime second) => first.year == second.year && first.month == second.month && first.day == second.day;

  Reminder _makeReminder(Reminder primary, String kind, DateTime at) {
    final isSnooze = kind == 'snooze';
    final kindTag = isSnooze ? 'snooze' : 'follow-up';
    return Reminder(
      id: '${primary.routineId}-$kindTag-${primary.dateKey}',
      routineId: primary.routineId,
      title: primary.title,
      body: isSnooze
          ? _english
                ? 'This is the reminder you snoozed.'
                : 'Pengingat yang kamu tunda.'
          : primary.routineId == 'penutup-hari'
          ? _english
                ? 'Your End of Day routine is still available if you have time.'
                : 'Kalau masih memungkinkan, rutinitas ini masih tersedia.'
          : _english
          ? '${primary.title} is still available if you have time.'
          : '${primary.title} masih tersedia. Kalau belum sempat, masih ada waktu.',
      scheduledAt: at,
      priority: primary.priority,
      type: isSnooze ? ReminderType.snooze : ReminderType.followUp,
      dateKey: primary.dateKey,
      timezoneIdentifier: primary.timezoneIdentifier,
    );
  }

  Reminder _template(String id, DateTime day, String timezone) {
    final key = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final title = switch (id) {
      'sholat-malam' => _english ? 'Night Prayer' : 'Sholat Malam',
      'subuh' => _english ? 'Fajr' : 'Subuh',
      'dhuha' => _english ? 'Dhuha' : 'Sholat Dhuha',
      'zuhur' => _english ? 'Dhuhr' : 'Sholat Zuhur',
      'asar' => _english ? 'Asr' : 'Sholat Asar',
      'maghrib' => _english ? 'Maghrib' : 'Sholat Maghrib',
      _ => _english ? 'Isha' : 'Sholat Isya',
    };
    return Reminder(id: '$id-primary-$key', routineId: id, title: title, body: '', scheduledAt: day, priority: const {'subuh', 'zuhur', 'asar', 'maghrib', 'isya', 'sholat-malam'}.contains(id) ? ReminderPriority.high : ReminderPriority.medium, dateKey: key, timezoneIdentifier: timezone);
  }

  static const _actionableRoutineIds = ['sholat-malam', 'subuh', 'dhuha', 'zuhur', 'asar', 'maghrib', 'isya', 'penutup-hari'];
}
