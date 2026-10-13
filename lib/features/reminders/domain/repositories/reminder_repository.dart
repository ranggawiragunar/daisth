import '../models/exact_alarm_status.dart';
import '../models/reminder.dart';
import '../models/reminder_permission_status.dart';
import '../models/reminder_scheduling_mode.dart';

abstract interface class ReminderRepository {
  Future<void> initialize({void Function(String? payload)? onNotificationTap});

  Future<String?> getLaunchPayload();

  Future<ReminderPermissionStatus> getPermissionStatus();

  Future<ReminderPermissionStatus> requestPermission();

  Future<ExactAlarmStatus> getExactAlarmStatus();

  Future<ExactAlarmStatus> requestExactAlarmPermission();

  Future<void> schedule(
    Reminder reminder, {
    required ReminderSchedulingMode mode,
  });

  Future<void> cancel(Reminder reminder);

  Future<void> cancelRemindersForDate(DateTime date);

  Future<void> cancelAllIstiqamReminders();

  Future<List<Reminder>> getPendingReminders();

  Future<bool> openNotificationSettings();
}
