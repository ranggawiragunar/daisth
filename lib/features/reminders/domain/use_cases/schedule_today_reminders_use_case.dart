import '../../../../core/timezone/domain/repositories/timezone_repository.dart';
import '../../../prayer_times/domain/models/prayer_day_schedule.dart';
import '../../../prayer_times/domain/use_cases/load_today_prayer_schedule_use_case.dart';
import '../models/exact_alarm_status.dart';
import '../models/reminder_schedule_summary.dart';
import '../models/reminder_scheduling_mode.dart';
import '../repositories/reminder_repository.dart';
import 'build_today_reminder_plan_use_case.dart';

class ScheduleTodayRemindersUseCase {
  ScheduleTodayRemindersUseCase({
    required this.reminderRepository,
    required this.timezoneRepository,
    required this.loadTodayPrayerSchedule,
    required this.buildTodayReminderPlan,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ReminderRepository reminderRepository;
  final TimezoneRepository timezoneRepository;
  final LoadTodayPrayerScheduleUseCase loadTodayPrayerSchedule;
  final BuildTodayReminderPlanUseCase buildTodayReminderPlan;
  final DateTime Function() _clock;

  Future<ReminderScheduleSummary> call({
    PrayerDaySchedule? schedule,
    DateTime? now,
  }) async {
    final current = now ?? _clock();
    var todaySchedule = schedule;
    if (todaySchedule == null || !_isSameDate(todaySchedule.date, current)) {
      todaySchedule = (await loadTodayPrayerSchedule(date: current)).schedule;
    }
    final deviceTimezone = await timezoneRepository.getDeviceTimezone();
    final plan = buildTodayReminderPlan(
      schedule: todaySchedule,
      timezone: deviceTimezone,
      now: current,
    );
    final exactStatus = await reminderRepository.getExactAlarmStatus();
    final mode = exactStatus == ExactAlarmStatus.enabled
        ? ReminderSchedulingMode.exact
        : ReminderSchedulingMode.inexact;

    await reminderRepository.cancelRemindersForDate(plan.date);
    for (final reminder in plan.reminders) {
      await reminderRepository.schedule(reminder, mode: mode);
    }
    return ReminderScheduleSummary(
      plan: plan,
      scheduledCount: plan.reminders.length,
      exactAlarmStatus: exactStatus,
    );
  }

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
