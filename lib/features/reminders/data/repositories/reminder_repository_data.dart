import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/models/exact_alarm_status.dart';
import '../../domain/models/reminder.dart';
import '../../domain/models/reminder_permission_status.dart';
import '../../domain/models/reminder_scheduling_mode.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../mappers/reminder_mapper.dart';
import '../services/reminder_notification_gateway.dart';

class ReminderRepositoryData implements ReminderRepository {
  ReminderRepositoryData({required this.service, required this.mapper});

  final ReminderNotificationGateway service;
  final ReminderMapper mapper;

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) => service.initialize(onNotificationTap: onNotificationTap);

  @override
  Future<String?> getLaunchPayload() => service.getLaunchPayload();

  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async =>
      _permissionStatus(await service.areNotificationsEnabled());

  @override
  Future<ReminderPermissionStatus> requestPermission() async =>
      _permissionStatus(await service.requestNotificationPermission());

  ReminderPermissionStatus _permissionStatus(bool? isEnabled) =>
      switch (isEnabled) {
        true => ReminderPermissionStatus.granted,
        false => ReminderPermissionStatus.denied,
        null => ReminderPermissionStatus.unavailable,
      };

  @override
  Future<ExactAlarmStatus> getExactAlarmStatus() async =>
      switch (await service.canScheduleExactNotifications()) {
        true => ExactAlarmStatus.enabled,
        false => ExactAlarmStatus.needsPermission,
        null => ExactAlarmStatus.unavailable,
      };

  @override
  Future<ExactAlarmStatus> requestExactAlarmPermission() async =>
      switch (await service.requestExactAlarmsPermission()) {
        true => ExactAlarmStatus.enabled,
        false => ExactAlarmStatus.needsPermission,
        null => ExactAlarmStatus.unavailable,
      };

  @override
  Future<void> schedule(
    Reminder reminder, {
    required ReminderSchedulingMode mode,
  }) => service.schedule(
    mapper.toScheduleData(reminder),
    scheduleMode: mode == ReminderSchedulingMode.exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
  );

  @override
  Future<void> cancel(Reminder reminder) async {
    final data = mapper.toScheduleData(reminder);
    await service.cancel(data.notificationId);
  }

  @override
  Future<void> cancelRemindersForDate(DateTime date) async {
    final pending = List.of(await service.getPendingRequests());
    for (final request in pending) {
      final reminder = _mapPending(request);
      if (reminder == null || !_isSameDate(reminder.scheduledAt, date)) {
        continue;
      }
      await service.cancel(request.id);
    }
  }

  @override
  Future<void> cancelAllIstiqamReminders() async {
    final pending = List.of(await service.getPendingRequests());
    for (final request in pending) {
      if (_isIstiqamPayload(request.payload)) await service.cancel(request.id);
    }
  }

  @override
  Future<List<Reminder>> getPendingReminders() async {
    final reminders =
        (await service.getPendingRequests())
            .map(_mapPending)
            .whereType<Reminder>()
            .toList()
          ..sort(
            (first, second) => first.scheduledAt.compareTo(second.scheduledAt),
          );
    return List.unmodifiable(reminders);
  }

  Reminder? _mapPending(PendingNotificationRequest request) =>
      mapper.fromPending(
        notificationId: request.id,
        title: request.title,
        body: request.body,
        payload: request.payload,
      );

  bool _isIstiqamPayload(String? payload) {
    if (payload == null) return false;
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> && decoded['app'] == 'istiqam';
    } on FormatException {
      return false;
    }
  }

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  Future<bool> openNotificationSettings() => service.openNotificationSettings();
}
