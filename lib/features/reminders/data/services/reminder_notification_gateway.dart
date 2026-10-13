import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/reminder_schedule_data.dart';

abstract interface class ReminderNotificationGateway {
  Future<void> initialize({void Function(String? payload)? onNotificationTap});

  Future<String?> getLaunchPayload();

  Future<bool?> areNotificationsEnabled();

  Future<bool?> requestNotificationPermission();

  Future<bool?> canScheduleExactNotifications();

  Future<bool?> requestExactAlarmsPermission();

  Future<void> schedule(
    ReminderScheduleData reminder, {
    required AndroidScheduleMode scheduleMode,
  });

  Future<void> cancel(int notificationId);

  Future<List<PendingNotificationRequest>> getPendingRequests();

  Future<bool> openNotificationSettings();
}
