import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/reminders/data/mappers/reminder_mapper.dart';
import 'package:daisth/features/reminders/data/models/reminder_schedule_data.dart';
import 'package:daisth/features/reminders/data/repositories/reminder_repository_data.dart';
import 'package:daisth/features/reminders/data/services/reminder_notification_gateway.dart';
import 'package:daisth/features/reminders/domain/models/exact_alarm_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder.dart';
import 'package:daisth/features/reminders/domain/models/reminder_permission_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder_priority.dart';
import 'package:daisth/features/reminders/domain/models/reminder_scheduling_mode.dart';

void main() {
  test('initializes gateway and maps notification permissions', () async {
    final gateway = _Gateway();
    final repository = _repository(gateway);
    String? tappedPayload;

    await repository.initialize(
      onNotificationTap: (payload) => tappedPayload = payload,
    );
    expect(gateway.initialized, isTrue);
    gateway.onNotificationTap?.call('tap-payload');
    expect(tappedPayload, 'tap-payload');

    gateway.notificationsEnabled = true;
    expect(
      await repository.getPermissionStatus(),
      ReminderPermissionStatus.granted,
    );
    gateway.notificationsEnabled = false;
    expect(
      await repository.getPermissionStatus(),
      ReminderPermissionStatus.denied,
    );
    gateway.notificationsEnabled = null;
    expect(
      await repository.getPermissionStatus(),
      ReminderPermissionStatus.unavailable,
    );

    gateway.requestedNotifications = true;
    expect(
      await repository.requestPermission(),
      ReminderPermissionStatus.granted,
    );
  });

  test('maps exact alarm state and requests user access', () async {
    final gateway = _Gateway()..exactEnabled = false;
    final repository = _repository(gateway);
    expect(
      await repository.getExactAlarmStatus(),
      ExactAlarmStatus.needsPermission,
    );
    gateway.requestedExact = true;
    expect(
      await repository.requestExactAlarmPermission(),
      ExactAlarmStatus.enabled,
    );
  });

  test(
    'schedules with stable plugin identity and preserves pending details',
    () async {
      final gateway = _Gateway();
      final repository = _repository(gateway);
      final reminder = _reminder('zuhur', DateTime(2026, 10, 13, 11, 50));

      await repository.schedule(reminder, mode: ReminderSchedulingMode.exact);
      final pending = await repository.getPendingReminders();

      expect(gateway.scheduled.single.notificationId, greaterThan(0));
      expect(gateway.scheduled.single.channelId, ReminderMapper.highChannelId);
      expect(
        gateway.scheduleModes.single,
        AndroidScheduleMode.exactAllowWhileIdle,
      );
      expect(pending.single.id, reminder.id);
      expect(pending.single.scheduledAt, reminder.scheduledAt);
    },
  );

  test(
    'cancels one reminder, reminders for one date, and Daisth only',
    () async {
      final gateway = _Gateway();
      final repository = _repository(gateway);
      final today = _reminder('zuhur', DateTime(2026, 10, 13, 11, 50));
      final tomorrow = _reminder('zuhur', DateTime(2026, 10, 14, 11, 50));
      final later = _reminder('asar', DateTime(2026, 10, 14, 15, 20));
      await repository.schedule(today, mode: ReminderSchedulingMode.inexact);
      await repository.schedule(tomorrow, mode: ReminderSchedulingMode.inexact);
      await repository.schedule(later, mode: ReminderSchedulingMode.inexact);
      gateway.pending.add(
        const PendingNotificationRequest(
          9000,
          'Other',
          'External',
          '{"app":"other"}',
        ),
      );

      await repository.cancelRemindersForDate(DateTime(2026, 10, 13));
      expect(gateway.cancelled, [
        ReminderMapper().toScheduleData(today).notificationId,
      ]);
      await repository.cancel(tomorrow);
      expect(
        gateway.pending.any(
          (request) =>
              request.payload == ReminderMapper().toScheduleData(later).payload,
        ),
        isTrue,
      );
      await repository.cancelAllDaisthReminders();

      expect(gateway.pending.map((request) => request.id), [9000]);
      expect(gateway.cancelled, hasLength(3));
    },
  );
}

ReminderRepositoryData _repository(_Gateway gateway) =>
    ReminderRepositoryData(service: gateway, mapper: ReminderMapper());

Reminder _reminder(String routineId, DateTime time) => Reminder(
  id: '$routineId-primary-${time.year}-${time.month}-${time.day}',
  routineId: routineId,
  title: 'Reminder title',
  body: 'Reminder body',
  scheduledAt: time,
  priority: ReminderPriority.high,
);

class _Gateway implements ReminderNotificationGateway {
  bool initialized = false;
  bool? notificationsEnabled = true;
  bool? exactEnabled = true;
  bool? requestedNotifications;
  bool? requestedExact;
  void Function(String? payload)? onNotificationTap;
  final pending = <PendingNotificationRequest>[];
  final scheduled = <ReminderScheduleData>[];
  final scheduleModes = <AndroidScheduleMode>[];
  final cancelled = <int>[];

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    initialized = true;
    this.onNotificationTap = onNotificationTap;
  }

  @override
  Future<String?> getLaunchPayload() async => null;
  @override
  Future<bool?> areNotificationsEnabled() async => notificationsEnabled;
  @override
  Future<bool?> requestNotificationPermission() async => requestedNotifications;
  @override
  Future<bool?> canScheduleExactNotifications() async => exactEnabled;
  @override
  Future<bool?> requestExactAlarmsPermission() async => requestedExact;
  @override
  Future<void> schedule(
    ReminderScheduleData reminder, {
    required AndroidScheduleMode scheduleMode,
  }) async {
    scheduled.add(reminder);
    scheduleModes.add(scheduleMode);
    pending.removeWhere((request) => request.id == reminder.notificationId);
    pending.add(
      PendingNotificationRequest(
        reminder.notificationId,
        reminder.title,
        reminder.body,
        reminder.payload,
      ),
    );
  }

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
    pending.removeWhere((request) => request.id == notificationId);
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingRequests() async =>
      pending;
  @override
  Future<bool> openNotificationSettings() async => true;
}
